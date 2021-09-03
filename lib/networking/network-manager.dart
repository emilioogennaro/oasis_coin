import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:oasis_coin/blockchain/blockchain.dart';
import 'package:oasis_coin/wallet/transaction.dart';

const int STANDARD_NETWORK_PORT = 5000;

class NetworkManager {
    late ServerSocket serverSocket;
    late Socket clientSocket;
    late List<int> fullNodesList;
    late Blockchain lastBlockchain;
    late List<Transaction> lastTransactions;
    
    NetworkManager(input){
        setUP(input);
    }

    void setUP(input) async {
        this.fullNodesList = [5001];
        this.lastBlockchain = Blockchain();
        this.lastTransactions = [];

        this.serverSocket = await ServerSocket.bind('localhost', input);
        this.clientSocket = await Socket.connect('localhost', input);
        this.listen();
    }

    void listen() async {
      serverSocket.listen((client) {handleConnection(client);});
    }

    void handleConnection(Socket client) async {
      print("Connection from ${client.remoteAddress.address}:${client.remotePort}");
      client.listen(
        (Uint8List data) async {
          handleData(data);
        }
      );
    }

    void handleData(Uint8List data) async {
        String message = String.fromCharCodes(data);
        print(message);
        if(message.substring(0,2) == "1/") {
            // blockchain
            message = message.substring(2);
            lastBlockchain.replaceFromJson(message);
        } else if (message.substring(0,2) == "0/") {
          // transaction
          message = message.substring(2);
          lastTransactions.add(Transaction.listFromMap(jsonDecode(message))[0]);
        }
    }

    void broadcast({blockchain, transaction}) async {
      if(blockchain != null || transaction != null) {
        print("ciao");
        for(int port in fullNodesList) {
          clientSocket.close();
          print("ciao2");
          clientSocket = await Socket.connect('localhost', port);
          if(blockchain != null) clientSocket.write("1/" + blockchain.toJson());
          if(transaction!= null) clientSocket.write("0/" + transaction.toJson());
        }
      }
    }

    Map<String,dynamic> getUpdates() {
      return {"chain": lastBlockchain.chain, "transactions": lastTransactions};
    }

}