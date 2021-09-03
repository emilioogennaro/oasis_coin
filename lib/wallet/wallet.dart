import 'package:eosdart_ecc/eosdart_ecc.dart';
import 'package:oasis_coin/blockchain/block.dart';
import 'package:oasis_coin/wallet/transaction.dart';

// provvisory STARTING_BALANCE for development purpose, TO_UPGRADE
const double STARTING_BALANCE = 10000;

class Wallet {
  // wallet balance
  late double balance = STARTING_BALANCE;
  // wallet private key (used to sign transactions)
  late EOSPrivateKey privateKey;
  // wallet public key (used to verify transactions)
  late EOSPublicKey publicKey;
  // wallet address (string representation of public key, used to keep track of balance in the chain record)
  late String address;
  Wallet() {
    // set balance to default value
    this.balance = STARTING_BALANCE;
    // generate random private key
    privateKey = EOSPrivateKey.fromRandom();
    // get public key from private key
    publicKey = privateKey.toEOSPublicKey();
    // stringify public key
    this.address = publicKey.toString();
  }

  // eosdart_ecc 
  EOSSignature sign(String data) {
    return this.privateKey.signString(data);
  }

  Transaction createTransaction(double amount, String recipient, List<Block> chain) {
    this.updateBalance(chain);

    if (amount > this.balance) {
      throw ("[Wallet.createTransaction] Amount exceeds value");
    }

    return Transaction(
        senderWallet: this, amount: amount, recipient: recipient);
  }

  double updateBalance(List<Block> chain) {
    bool hasConductedTransaction = false;
    double newBalance = 0;

    for (int i = chain.length - 1; i > 0; i--) {
      Block block = chain[i];
      for (Transaction transaction in block.transactions) {
        if (transaction.input["address"] == this.address) {
          hasConductedTransaction = true;
        }
        if (transaction.outputMap.containsKey(this.address)) {
          newBalance += transaction.outputMap[this.address];
        }
      }

      if (hasConductedTransaction) {
        break;
      }
    }

    if (hasConductedTransaction) {
      this.balance = newBalance;
      return newBalance;
    } else {
      this.balance = newBalance + STARTING_BALANCE;
      return newBalance + STARTING_BALANCE;
    }
  }

  static double calculateBalance(List<Block> chain, String address, {int ceil = -1}) {
    bool hasConductedTransaction = false;
    double newBalance = 0;
    if (ceil == -1) {
      ceil = chain.length - 1;
    }
    for (int i = ceil; i > 0; i--) {
      Block block = chain[i];
      for (Transaction transaction in block.transactions) {
        if (transaction.input["address"] == address) {
          hasConductedTransaction = true;
        }
        if (transaction.outputMap.containsKey(address)) {
          newBalance += transaction.outputMap[address];
        }
      }
      if (hasConductedTransaction) {
        break;
      }
    }
    if (hasConductedTransaction) {
      return newBalance;
    } else {
      return newBalance + STARTING_BALANCE;
    }
  }
}
