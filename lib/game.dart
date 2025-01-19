import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localpkg/dialogue.dart';
import 'package:localpkg/functions.dart';
import 'package:localpkg/widgets.dart';
import 'package:localpkg/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class Game extends StatefulWidget {
  final int mode;
  final String? code;
  final int goal;

  const Game({
    super.key,
    required this.mode,
    this.code,
    required this.goal,
  });

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> {
  bool useZero = true;
  int id = 3;
  int players = 4;
  int handmode = 0; // 0: no play; 1: numer; 2: discard; 3: action
  int actionsPlayed = 0;
  int nextup = 0;
  io.Socket? socket;
  Map memory = {
    "players": [
      {
        "id": 1,
        "cards": [
          {
            "type": "roofred",
          },
          {
            "type": null,
          },
          {
            "type": "roofblue",
          },
        ],
        "currentCard": {
          "type": "3",
        },
      },
      {
        "id": 2,
        "cards": [
          {
            "type": "roofred",
          },
          {
            "type": null,
          },
          {
            "type": "roofblue",
          },
        ],
        "currentCard": {
          "type": "3",
        },
      },
      {
        "id": 3,
        "cards": [
          {
            "type": null,
          },
          {
            "type": null,
          },
          {
            "type": "roofblue",
          },
        ],
        "currentCard": {
          "type": "1",
        },
      },
      {
        "id": 4,
        "cards": [
          {
            "type": "roofred",
          },
          {
            "type": null,
          },
          {
            "type": "roofblue",
          },
        ],
        "currentCard": {
          "type": "3",
        },
      },
    ],
    "hand": [
      {
        "type": "skip1",
      },
      {
        "type": "skip2",
      },
      {
        "type": "remove1",
      },
      {
        "type": "remove2",
      },
      {
        "type": "remove5",
      },
      {
        "type": "stealnum",
      },
      {
        "type": "stealroof",
      },
    ],
    "drawn": [
      {
        "type": "roofred",
      },
      {
        "type": "roofgreen",
      },
      {
        "type": "roofblue",
      },
      {
        "type": "1",
      },
      {
        "type": "3",
      },
      {
        "type": "2",
      },
      {
        "type": "8",
      },
      {
        "type": "6",
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    if (id == 1) {
      myTurn();
    }
  }

  void myTurn() {
    if (memory["players"][id - 1] != null) {
      nextup = id - 1;
    } else {
      nextup = 1;
    }
    handmode = 1;
    refresh();
  }

  void refresh({bool mini = false}) {
    if (mini) {
      setState(() {});
    }
    print("refreshing...");
    setState(() {});
  }

  bool isRoofCard(String type) {
    return (type == "roofred" || type == "roofgreen" || type == "roofblue");
  }

  @override
  Widget build(BuildContext context) {
    Map data = memory["players"].firstWhere((item) => item["id"] == id);
    List hand = memory["hand"];
    if (handmode == 1 || handmode == 2) {
      hand = memory["drawn"];
    }

    print("handmode,nextup: $handmode,$nextup");
    print("building scaffold...");

    return Scaffold(
      appBar: AppBar(
        title: Text("Room: ${widget.code ?? "singleplayer"} • ID: $id", style: TextStyle(
          fontSize: 12
        )),
        centerTitle: true,
        toolbarHeight: 48.0,
        leading: GameCloseButton(),
        actions: [
          if (widget.code != null)
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.code!));
              showSnackBar(context, "Code copied!");
            },
          ),
          if (kDebugMode)
          IconButton(
            icon: Icon(Icons.abc),
            onPressed: () {
              TextEditingController controller = TextEditingController();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Enter handmode'),
                    content: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Enter number here'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          String input = controller.text;
                          Navigator.pop(context, input);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ).then((value) {
                  if (value != null && value.isNotEmpty) {
                    handmode = int.tryParse(value) ?? handmode;
                    refresh();
                  }
                });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  ...List.generate(players, (index) {
                    int i = index + 1;
                    if (i != id) {
                      return Player(player: i);
                    } else {
                      return SizedBox.shrink();
                    }
                  }),
                ],
              ),
            ),
            Section(
              expanded: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GameCard(card: (memory["currentDiscard"] ?? {"type": null})["type"], useZero: useZero),
                  GameCard(card: "cover"),
                  GameCard(customColor: handmode != 0 ? Colors.green : null, customChild: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (handmode == 0) {
                          return;
                        }
                        if (handmode == 2) {
                          print("setting discard...");
                          memory["currentDiscard"] = hand[hand.length - 1];
                        }
                        int oldMode = handmode;
                        handmode = (handmode == 1 ? 2 : (handmode == 2 ? 3 : 0));
                        print("switched to handmode: $oldMode:$handmode");
                        refresh();
                      },
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        alignment: Alignment.center,
                        child: Icon(Icons.check, color: getColor(context: context, type: ColorType.theme)),
                      ),
                    ),
                  )),
                ],
              ),
            ),
            Section(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DragTarget(
                      onWillAcceptWithDetails: (data) => true,
                      onAcceptWithDetails: (details) {
                        Map drag = details.data as Map<String, dynamic>;
                        int from = drag["index"];
                        print("card dragged: $from");
                        int currentCard = int.tryParse(data["currentCard"]["type"]) ?? 0;
                        int? newCard = int.tryParse(hand[from]["type"]);
                        if (newCard == null) {
                          print("invalid");
                          return;
                        }
                        bool valid = newCard == (currentCard + 1);
                        print("setting card $currentCard:$newCard:$valid ($newCard == ($currentCard + 1))");
                        if (valid && handmode == 1) {
                          print("valid");
                          data["currentCard"] = hand[from];
                          hand.removeAt(from);
                        } else {
                          print("invalid: $valid,$handmode");
                        }
                        refresh();
                      },
                      builder: (context, candidateData, rejectedData) {
                        return GameCard(card: data["currentCard"]["type"], active: handmode == 1);
                      },
                    ),
                    ...data["cards"].asMap().map((index, item) {
                      return MapEntry(index, DragTarget(
                        onWillAcceptWithDetails: (data) => true,
                        onAcceptWithDetails: (details) {
                          Map drag = details.data as Map<String, dynamic>;
                          int from = drag["index"];
                          print("card dragged: $from:$index");
                          String type = drag["item"]["type"];
                          bool contains = data["cards"].any((item) => item['type'] == drag["item"]["type"]);
                          bool empty = data["cards"][index]["type"] == null;
                          bool isRoof = isRoofCard(type);
                          if (isRoof && empty && !contains && handmode == 2) {
                            print("valid");
                            data["cards"][index] = hand[from];
                            memory["currentDiscard"] = hand[hand.length - 1];
                            handmode = 0;
                            refresh();
                          } else {
                            print("invalid: $isRoof,$empty,$contains,$handmode (expected true,true,false,2)");
                          }
                          refresh();
                        },
                        builder: (context, candidateData, rejectedData) {
                          return GameCard(card: item["type"], active: handmode == 2);
                        },
                      ));
                    }).values.toList(),
                  ],
                ),
              ),
            ),
            Section(
              expanded: false,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(hand.length, (index) {
                    List handS = hand;
                    Map item = hand[index];

                    return Draggable(
                      data: {"index": index, "item": item},
                      feedback: Material(
                        color: Colors.transparent,
                        child: GameCard(card: item["type"]),
                      ),
                      childWhenDragging: Opacity(opacity: 0.3, child: GameCard(card: item["type"])),
                      child: DragTarget(
                        onWillAcceptWithDetails: (data) => true,
                        onAcceptWithDetails: (details) {
                          print("moving item...");
                          Map draggedItem = details.data as Map<String, dynamic>;
                          print("drag data: $draggedItem");
                          int oldIndex = draggedItem["index"];
                          int newIndex = index;
                          print("moving card ${item["type"]}: $oldIndex:$newIndex");
                          handS.removeAt(oldIndex);
                          handS.insert(newIndex, draggedItem["item"]);
                          hand = handS;
                          refresh();
                        },
                        builder: (context, candidateData, rejectedData) {
                          return GameCard(card: item["type"]);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget GameCard({Color? customColor, Widget? customChild, bool active = false, String? card, double size = 1, int drawStack = 0, double padding = 8, bool useZero = false}) {
    if (card == "0") {
      card = null;
    }
    if (useZero) {
      card ??= "0";
    }
    bool draw = card == "draw";
    bool image = !(card == null || draw);
    return Padding(
      padding: EdgeInsets.all(padding * size),
      child: Container(
        width: 55 * size,
        height: 80 * size,
        child: customChild == null ? (draw ? Center(child: Text("$drawStack", style: TextStyle(color: getColor(context: context, type: ColorType.primary), fontSize: 36))) : SizedBox.shrink()) : Center(child: customChild),
        decoration: BoxDecoration(
          color: customColor ?? (draw ? Colors.white : null),
          border: Border.all(width: 2 * size, color: (active ? Colors.orange : getColor(context: context, type: ColorType.theme))),
          borderRadius: BorderRadius.all(Radius.circular(5)),
          image: image && (customChild == null) ? DecorationImage(
            image: AssetImage('assets/card/$card.png'),
            fit: BoxFit.fill,
          ) : null,
        ),
      ),
    );
  }

  Widget Player({required int player}) {
    Map data = memory["players"].firstWhere((item) => item["id"] == player);
    List cards = [data["currentCard"], ...data["cards"]];
    return Expanded(
      child: DragTarget(
        builder: (context, candidateData, rejectedData) {
          return Center(
            child: Column(
              children: [
                Text("Player $player"),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 4,
                  children: [
                    ...cards.asMap().entries.map((entry) {
                      int index = entry.key;
                      var item = entry.value;
                      return GameCard(
                        card: item["type"],
                        padding: 4,
                        useZero: index == 0 ? useZero : false,
                      );
                    }),
                  ],
                ),
              ],
            ),
          );
        },
        onWillAcceptWithDetails: (data) => true,
        onAcceptWithDetails: (details) async {
          print("dragged to player $player");
          if (handmode != 3) {
            return;
          }
          Map drag = details.data as Map<String, dynamic>;
          String type = drag["item"]["type"];
          actionsPlayed++;
          switch (type) {
            case 'remove1' || 'remove2' || 'remove5':
              int current = int.tryParse(data["currentCard"]["type"]) ?? 0;
              int remove = int.parse(type.replaceAll('remove', ''));
              int after = current - remove;
              after = after < 0 ? 0 : after;
              data["currentCard"]["type"] = "$after";
              print("removed $remove from $player: $current:$after");
              refresh();
              break;
            case 'skip1' || 'skip2':
              int skip = int.parse(type.replaceAll('skip', ''));
              print("new skip: $skip");
              nextup = ((nextup + skip - 1) % memory["players"].length + 1).toInt();
              print("set nextup to $nextup");
              refresh();
              break;
            case 'stealnum':
              int current = int.tryParse(data["currentCard"]["type"]) ?? 0;
              int after = current - 1;
              if (current == 0) {
                actionsPlayed++;
                showSnackBar(context, "There's no card to steal!");
                break;
              }
              memory["hand"].add(data["currentCard"]);
              data["currentCard"]["type"] = "$after";
              break;
            case 'stealroof':
              break;
            default:
              actionsPlayed--;
              break;
          }
          if (actionsPlayed >= 2) {
            handmode = 0;
          }
        },
      ),
    );
  }

  Widget GameCloseButton() {
    return IconButton(
      icon: Icon(Icons.cancel_outlined),
      onPressed: () async {
        if (await showConfirmDialogue(context: context, title: "Exit the match?", description: "Are you sure you want to exit the match? You will not be able to rejoin.") ?? false) {
          print("disconnecting...");
          socket?.disconnect();
        }
      },
      iconSize: 32,
    );
  }
}