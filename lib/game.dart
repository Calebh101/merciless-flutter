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
  int id = 3;
  int players = 4;
  int handmode = 1; // 0: hand; 1: play; 2: discard; 3: play discard
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
        "type": "roofred",
      },
      {
        "type": null,
      },
      {
        "type": "roofblue",
      },
      {
        "type": null,
      },
      {
        "type": null,
      },
      {
        "type": "roofred",
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

  void refresh({bool mini = false}) {
    if (mini) {
      setState(() {});
    }
    print("refreshing...");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Map data = memory["players"].firstWhere((item) => item["id"] == id);
    List hand = memory["hand"];
    if (handmode == 1 || handmode == 2) {
      hand = memory["drawn"];
    }

    print("scanning hand:cards");
    bool discardPossible = true;
    bool anyEmpty = false;
    bool missing = false;

    if (handmode == 2) {
      hand.asMap().forEach((index, value) {
        if (value["type"] == null) {
          anyEmpty = true;
        }
      });

      missing = data["cards"].any((itemA) {
        return !hand.any((itemB) => itemB['type'] == itemA['type']);
      });

      if (!anyEmpty) {
        discardPossible = false;
      }

      if (missing) {
        discardPossible = true;
      }
    }

    print("discard possible: $anyEmpty:$missing ($discardPossible)");
    print("handmode: $handmode");
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
                  GameCard(card: memory["currentDiscard"]),
                  GameCard(card: "cover"),
                  GameCard(customColor: handmode == 1 ? Colors.green : null, customChild: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (handmode != 1) {
                          return;
                        }
                        handmode = 2;
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
                        int newCard = int.tryParse(hand[from]["type"]) ?? 0;
                        bool valid = newCard == (currentCard + 1);
                        print("setting card $currentCard:$newCard:$valid ($newCard == ($currentCard + 1))");
                        if (valid && handmode == 1) {
                          print("valid");
                          data["currentCard"] = hand[from];
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
                      if (handmode == 2 && !discardPossible) {
                        handmode = 0;
                        refresh();
                      }
                      return MapEntry(index, DragTarget(
                        onWillAcceptWithDetails: (data) => true,
                        onAcceptWithDetails: (details) {
                          Map drag = details.data as Map<String, dynamic>;
                          int from = drag["index"];
                          print("card dragged: $from:$index");
                          String? type = drag["item"]["type"];
                          bool contains = data["cards"].any((item) => item['type'] == drag["item"]["type"]);
                          bool empty = data["cards"][index]["type"] == null;
                          bool isRoof = (type == "roofred" || type == "roofgreen" || type == "roofblue");
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

  Widget GameCard({Color? customColor, Widget? customChild, bool active = false, String? card, double size = 1, int drawStack = 0}) {
    bool draw = card == "draw";
    bool image = !(card == null || draw);
    return Padding(
      padding: EdgeInsets.all(8 * size),
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
    return Expanded(
      child: Container(
        child: Center(
          child: Column(
            children: [
              Text("Player $player"),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 3 / 4,
                children: [
                  GameCard(card: data["currentCard"]["type"]),
                  ...data["cards"].map((item) {
                    return GameCard(
                      card: item["type"],
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
        ),
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