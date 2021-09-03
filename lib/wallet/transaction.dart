import 'dart:convert';
import 'package:eosdart_ecc/eosdart_ecc.dart';
import 'package:oasis_coin/wallet/wallet.dart';
import 'package:uuid/uuid.dart';

const double MINER_REWARD = 10;
const Map<String, String> REWARD_INPUT = {"address": "*AUTH-REWARD*"};

class Transaction {
  final Uuid uuid = Uuid();
  late String id;
  late Map outputMap;
  late Map input;
  Transaction({senderWallet, amount, recipient, newId, newInput, newOutputMap, bool fromData = false}) {
    if (fromData) {
      this.id = newId;
      this.input = newInput;
      this.outputMap = newOutputMap;
      return;
    }
    this.id = uuid.v1();
    this.outputMap = this.createOutputMap(senderWallet, recipient, amount);
    this.input = this.createInput(senderWallet, this.outputMap);
  }

  Map<String,double> createOutputMap(Wallet senderWallet, String recipient, double amount) {
    Map<String,double> outputMap = Map();
    outputMap["$recipient"] = amount;
    outputMap["${senderWallet.address}"] = senderWallet.balance - amount;
    return outputMap;
  }

  Map<String,dynamic> createInput(Wallet senderWallet, Map outputMap) {
    Map<String,dynamic> input = Map();
    input["timestamp"] = DateTime.now().millisecondsSinceEpoch;
    input["amount"] = senderWallet.balance;
    input["address"] = senderWallet.address;
    input["signature"] = senderWallet.sign(jsonEncode(outputMap));
    return input;
  }

  bool update(Wallet senderWallet, recipient, double amount) {
    if (amount > this.outputMap[senderWallet.address]) {
      throw ("[Transaction.update] Amount exceeds balance");
    }
    if (!this.outputMap.containsKey(recipient)) {
      this.outputMap[recipient] = amount;
    } else {
      this.outputMap[recipient] += amount;
    }
    this.outputMap[senderWallet.address] -= amount;
    this.input = this.createInput(senderWallet, this.outputMap);
    return true;
  }

  static bool verifyTransaction(Transaction transaction) {
    double outputTotal = transaction.outputMap.values.reduce((a, b) => a + b);

    if (transaction.input["amount"] != outputTotal) {
      print("Invalid transaction from ${transaction.input['address']}");
      return false;
    }

    if (!verifySignature(transaction.input["signature"], jsonEncode(transaction.outputMap), transaction.input["address"])) {
      print("Invalid signature from ${transaction.input['address']}");
      return false;
    }

    return true;
  }

  static bool verifySignature(EOSSignature signature, String data, String address) {
    return signature.verify(data, EOSPublicKey.fromString(address));
  }

  static Transaction rewardTransaction(Wallet minerWallet) {
    Transaction reward = Transaction(
        senderWallet: minerWallet,
        amount: MINER_REWARD,
        recipient: minerWallet.address);

    reward.outputMap = {minerWallet.address: MINER_REWARD};
    reward.input = {"address": "*AUTH-REWARD*"};

    return reward;
  }

  String toJson() {
    String json = "{ ";
    json += '"id": "${this.id}", ';

    json += '"input": { ';
    for (var item in this.input.keys) {
      if (item == "timestamp" || item == "amount")
        json += '"$item": ${this.input[item]}, ';
      else
        json += '"$item": "${this.input[item]}", ';
    }

    json = json.substring(0, json.length - 2);
    json += "}, ";

    json += '"outputMap": { ';
    for (var item in this.outputMap.keys) {
      json += '"$item": ${this.outputMap[item]}, ';
    }

    json = json.substring(0, json.length - 2);

    json += "} }";
    return json;
  }

  static String listToJson(List<Transaction> transactions) {
    if (transactions.length == 0) {
      return "{ }";
    }

    String json = "{ ";
    for (Transaction transaction in transactions) {
      json += '"${transaction.id}": { ';
      json += '"id": "${transaction.id}", ';

      json += '"input": { ';
      for (var item in transaction.input.keys) {
        if (item == "timestamp" || item == "amount")
          json += '"$item": ${transaction.input[item]}, ';
        else
          json += '"$item": "${transaction.input[item]}", ';
      }

      json = json.substring(0, json.length - 2);
      json += "}, ";

      json += '"outputMap": { ';
      for (var item in transaction.outputMap.keys) {
        json += '"$item": ${transaction.outputMap[item]}, ';
      }

      json = json.substring(0, json.length - 2);
      json += "} } }";
    }
    return json;
  }

  static List<Transaction> listFromMap(Map transactionsMap) {
    List<Transaction> transactionList = [];
    if (transactionsMap.isEmpty) return transactionList;

    for (var key in transactionsMap.keys) {
      transactionList.add(Transaction(
          fromData: true,
          newId: transactionsMap[key]["id"],
          newInput: transactionsMap[key]["input"],
          newOutputMap: transactionsMap[key]["outputMap"]));

      transactionList.last.input["signature"] = EOSSignature.fromString(transactionList.last.input["signature"]);
    }
    transactionList.sort((a, b) => a.input["timestamp"] > b.input["timestamp"]);
    return transactionList;
  }
}
