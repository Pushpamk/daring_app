import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/anchoredoverlay.dart';
import '../widgets/centerabout.dart';

import './matches.dart';

enum SlideDirection { left, right, up }
enum SlideRegion { inNopeRegion, inLikeRegion, inSuperLikeRegion }

class DraggableCard extends StatefulWidget {
  final Widget card;
  final bool isDraggable;
  final SlideDirection slideTo;
  final SlideRegion slideRegion;
  final Function(double distance) onSlideUpdate;
  final Function(SlideRegion slideRegion) onSlideRegionUpdate;
  final Function(SlideDirection direction) onSlideOutComplete;

  DraggableCard(
      {this.card,
      this.isDraggable = true,
      this.onSlideUpdate,
      this.onSlideOutComplete,
      this.slideTo,
      this.slideRegion,
      this.onSlideRegionUpdate});
  @override
  _DraggableCardState createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard>
    with TickerProviderStateMixin {
  Decision decision;
  GlobalKey profileCardKey = new GlobalKey(debugLabel: 'profile_card_key');
  Offset cardOffset = const Offset(0.0, 0.0);
  Offset dragStart;
  Offset dragPosition;
  Offset slideBackStart;
  SlideDirection slideOutDirection;
  SlideRegion slideRegion;
  AnimationController slideBackAnimation;
  Tween<Offset> slideOutTween;
  AnimationController slideOutAnimation;

  @override
  void initState() {
    super.initState();
    print("draggable ${widget.isDraggable}");

    slideBackAnimation = new AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )
      ..addListener(() => setState(() {
            cardOffset = Offset.lerp(
              slideBackStart,
              const Offset(0.0, 0.0),
              Curves.elasticOut.transform(slideBackAnimation.value),
            );

            print("draggable ${widget.isDraggable}");

            if (null != widget.onSlideUpdate) {
              widget.onSlideUpdate(cardOffset.distance);
            }

            if (null != widget.onSlideRegionUpdate) {
              widget.onSlideRegionUpdate(slideRegion);
            }
          }))
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            dragStart = null;
            slideBackStart = null;
            dragPosition = null;
          });
        }
      });

    slideOutAnimation = new AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )
      ..addListener(() {
        setState(() {
          cardOffset = slideOutTween.evaluate(slideOutAnimation);

          if (null != widget.onSlideUpdate) {
            widget.onSlideUpdate(cardOffset.distance);
          }

          if (null != widget.onSlideRegionUpdate) {
            widget.onSlideRegionUpdate(slideRegion);
          }
        });
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            dragStart = null;
            dragPosition = null;
            slideOutTween = null;

            if (widget.onSlideOutComplete != null) {
              widget.onSlideOutComplete(slideOutDirection);
            }
          });
        }
      });
  }

  @override
  void didUpdateWidget(DraggableCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.card.key != oldWidget.card.key) {
      cardOffset = const Offset(0.0, 0.0);
    }

    if (oldWidget.slideTo == null && widget.slideTo != null) {
      switch (widget.slideTo) {
        case SlideDirection.left:
          _slideLeft();
          break;
        case SlideDirection.right:
          _slideRight();
          break;
        case SlideDirection.up:
          _slideUp();
          break;
      }
    }

//    if (oldWidget.slideRegion == null && widget.slideRegion != null) {
//      switch (widget.slideRegion) {
//        case SlideDirection.left:
//          _slideLeft();
//          break;
//        case SlideDirection.right:
//          _slideRight();
//          break;
//        case SlideDirection.up:
//          _slideUp();
//          break;
//      }
//    }
  }

  @override
  void dispose() {
    slideBackAnimation.dispose();
    super.dispose();
  }

  Offset _chooseRandomDragStart() {
    final cardContext = profileCardKey.currentContext;
    final cardTopLeft = (cardContext.findRenderObject() as RenderBox)
        .localToGlobal(const Offset(0.0, 0.0));
    final dragStartY = cardContext.size.height *
            (new Random().nextDouble() < 0.5 ? 0.25 : 0.75) +
        cardTopLeft.dy;
    return new Offset(cardContext.size.width / 2 + cardTopLeft.dx, dragStartY);
  }

  void _slideLeft() async {
    await Future.delayed(Duration(milliseconds: 1)).then((_) {
      final screenWidth = context.size.width;
      dragStart = _chooseRandomDragStart();
      slideOutTween = new Tween(
          begin: const Offset(0.0, 0.0),
          end: new Offset(-2 * screenWidth, 0.0));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _slideRight() async {
    await Future.delayed(Duration(milliseconds: 1)).then((_) {
      final screenWidth = context.size.width;
      dragStart = _chooseRandomDragStart();
      slideOutTween = new Tween(
          begin: const Offset(0.0, 0.0), end: new Offset(2 * screenWidth, 0.0));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _slideUp() async {
    await Future.delayed(Duration(milliseconds: 1)).then((_) {
      final screenHeight = context.size.height;
      dragStart = _chooseRandomDragStart();
      slideOutTween = new Tween(
          begin: const Offset(0.0, 0.0),
          end: new Offset(0.0, -2 * screenHeight));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _onPanStart(DragStartDetails details) {
    dragStart = details.globalPosition;

    if (slideBackAnimation.isAnimating) {
      slideBackAnimation.stop(canceled: true);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final isInLeftRegion = (cardOffset.dx / context.size.width) < -0.45;
    final isInRightRegion = (cardOffset.dx / context.size.width) > 0.45;
    final isInTopRegion = (cardOffset.dy / context.size.height) < -0.40;

    setState(() {
      if (isInLeftRegion || isInRightRegion) {
        slideRegion = isInLeftRegion
            ? SlideRegion.inNopeRegion
            : SlideRegion.inLikeRegion;
      } else if (isInTopRegion) {
        slideRegion = SlideRegion.inSuperLikeRegion;
      } else {
        slideRegion = null;
      }

      dragPosition = details.globalPosition;
      cardOffset = dragPosition - dragStart;

      if (null != widget.onSlideUpdate) {
        widget.onSlideUpdate(cardOffset.distance);
      }

      if (null != widget.onSlideRegionUpdate) {
        widget.onSlideRegionUpdate(slideRegion);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final dragVector = cardOffset / cardOffset.distance;

    final isInLeftRegion = (cardOffset.dx / context.size.width) < -0.45;
    final isInRightRegion = (cardOffset.dx / context.size.width) > 0.45;
    final isInTopRegion = (cardOffset.dy / context.size.height) < -0.40;

    setState(() {
      if (isInLeftRegion || isInRightRegion) {
        slideOutTween = new Tween(
            begin: cardOffset, end: dragVector * (2 * context.size.width));
        slideOutAnimation.forward(from: 0.0);

        slideOutDirection =
            isInLeftRegion ? SlideDirection.left : SlideDirection.right;
      } else if (isInTopRegion) {
        slideOutTween = new Tween(
            begin: cardOffset, end: dragVector * (2 * context.size.height));
        slideOutAnimation.forward(from: 0.0);

        slideOutDirection = SlideDirection.up;
      } else {
        slideBackStart = cardOffset;
        slideBackAnimation.forward(from: 0.0);
      }

      slideRegion = null;
      if (null != widget.onSlideRegionUpdate) {
        widget.onSlideRegionUpdate(slideRegion);
      }
    });
  }

  double _rotation(Rect dragBounds) {
    if (dragStart != null) {
      final rotationCornerMultiplier =
          dragStart.dy >= dragBounds.top + (dragBounds.height / 2) ? -1 : 1;
      return (pi / 8) *
          (cardOffset.dx / dragBounds.width) *
          rotationCornerMultiplier;
    } else {
      return 0.0;
    }
  }

  Offset _rotationOrigin(Rect dragBounds) {
    if (dragStart != null) {
      return dragStart - dragBounds.topLeft;
    } else {
      return const Offset(0.0, 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new AnchoredOverlay(
      showOverlay: true,
      child: new Center(),
      overlayBuilder: (BuildContext context, Rect anchorBounds, Offset anchor) {
        return CenterAbout(
          position: anchor,
          child: new Transform(
            transform:
                new Matrix4.translationValues(cardOffset.dx, cardOffset.dy, 0.0)
                  ..rotateZ(_rotation(anchorBounds)),
            origin: _rotationOrigin(anchorBounds),
            child: new Container(
              key: profileCardKey,
              width: anchorBounds.width,
              height: anchorBounds.height,
              padding: const EdgeInsets.all(16.0),
              child: new GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: widget.card,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Draggable1CardState extends State<DraggableCard>
    with TickerProviderStateMixin<DraggableCard> {
  Decision decision;
  GlobalKey profileCardKey = new GlobalKey(debugLabel: "profile_card_key");
  Offset cardOffset = const Offset(0.0, 0.0);
  Offset dragStart;
  Offset dragPosition;
  Offset slideBackStart;
  SlideDirection slideOutDirection;
  AnimationController slideBackAnimation;
  Tween<Offset> slideOutTween;
  AnimationController slideOutAnimation;

  @override
  void initState() {
    super.initState();
    slideBackAnimation = new AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this)
      ..addListener(() => setState(() {
            cardOffset = Offset.lerp(
              slideBackStart,
              const Offset(0.0, 0.0),
              Curves.elasticOut.transform(slideBackAnimation.value),
            );

            if (null != widget.onSlideUpdate) {
              widget.onSlideUpdate(cardOffset.distance);
            }
          }))
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            dragStart = null;
            slideBackStart = null;
            dragPosition = null;
          });
        }
      });

    slideOutAnimation = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 500))
      ..addListener(() {
        setState(() {
          cardOffset = slideOutTween.evaluate(slideOutAnimation);

          if (null != widget.onSlideUpdate) {
            widget.onSlideUpdate(cardOffset.distance);
          }
        });
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            dragStart = null;
            dragPosition = null;
            slideOutTween = null;
            //cardOffset = const Offset(0.0, 0.0);

            //widget.matchEngine.resetMatch();
            if (widget.onSlideOutComplete != null) {
              widget.onSlideOutComplete(slideOutDirection);
            }
          });
        }
      });

    //widget.matchEngine.addListener(_onMatchChange);
    //decision = widget.matchEngine.decision;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    //widget.matchEngine.removeListener(_onMatchChange);
    slideBackAnimation.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DraggableCard oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
//    if (widget.matchEngine != oldWidget.matchEngine) {
//      oldWidget.matchEngine.removeListener(_onMatchChange);
//      widget.matchEngine.addListener(_onMatchChange);
//    }

    if (widget.card.key != oldWidget.card.key) {
      cardOffset = const Offset(0.0, 0.0);
    }

    if (oldWidget.slideTo == null && widget.slideTo != null) {
      switch (widget.slideTo) {
        case SlideDirection.left:
          _slideLeft();
          break;
        case SlideDirection.right:
          _slideRight();
          break;
        case SlideDirection.up:
          _slideUp();
          break;
      }
    }
  }

  Offset _chooseRandomDragStart() {
    final cardContext = profileCardKey.currentContext;
    final cardToLeft = (cardContext.findRenderObject() as RenderBox)
        .localToGlobal(const Offset(0.0, 0.0));
    final dragStartY = cardContext.size.height *
            (new Random().nextDouble() < 0.5 ? 0.25 : 0.75) +
        cardToLeft.dy;
    return new Offset(cardContext.size.width / 2 + cardToLeft.dx, dragStartY);
  }

  void _slideLeft() async {
    await Future.delayed(Duration(milliseconds: 500)).then((_) {
      final screenWidth = context.size.width;
      dragStart = _chooseRandomDragStart();
      slideOutTween = new Tween(
          begin: const Offset(0.0, 0.0),
          end: new Offset(-2 * screenWidth, 0.0));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _slideRight() async {
    await Future.delayed(Duration(milliseconds: 500)).then((_) {
      final screenWidth = context.size.width;
      dragStart = _chooseRandomDragStart();
      slideOutTween = new Tween(
          begin: const Offset(0.0, 0.0), end: new Offset(2 * screenWidth, 0.0));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _slideUp() async {
    await Future.delayed(Duration(milliseconds: 500)).then((_) {
      final screenHeight = context.size.height;
      dragStart = _chooseRandomDragStart();
      slideOutTween = new Tween(
          begin: const Offset(0.0, 0.0),
          end: new Offset(0.0, -2 * screenHeight));
      slideOutAnimation.forward(from: 0.0);
    });
  }

  void _onPanStart(DragStartDetails details) {
    dragStart = details.globalPosition;
    if (slideBackAnimation.isAnimating) {
      slideBackAnimation.stop(canceled: true);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      dragPosition = details.globalPosition;
      cardOffset = dragPosition - dragStart;

      if (null != widget.onSlideUpdate) {
        widget.onSlideUpdate(cardOffset.distance);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final dragVector = cardOffset / cardOffset.distance;
    final isInLeftRegion = (cardOffset.dx / context.size.width) < 0.45;
    final isInRightRegion = (cardOffset.dx / context.size.width) > 0.45;
    final isInTopRegion = (cardOffset.dy / context.size.height) < -0.40;

    setState(() {
      if (isInLeftRegion || isInRightRegion) {
        slideOutTween = new Tween(
            begin: cardOffset, end: dragVector * (2 * context.size.width));
        slideOutAnimation.forward(from: 0.0);

        slideOutDirection =
            isInLeftRegion ? SlideDirection.left : SlideDirection.right;
      } else if (isInTopRegion) {
        slideOutTween = new Tween(
            begin: cardOffset, end: dragVector * (2 * context.size.height));
        slideOutAnimation.forward(from: 0.0);
        slideOutDirection = SlideDirection.up;
      } else {
        slideBackStart = cardOffset;
        slideBackAnimation.forward(from: 0.0);
      }
    });
  }

  //handles the card rotation
  double _rotation(Rect dragBounds) {
    if (dragStart != null) {
      final rotationCornerMultiplier =
          dragStart.dy >= dragBounds.top + (dragBounds.height / 2) ? -1 : 1;
      return (pi / 8) *
          (cardOffset.dx / dragBounds.width) *
          rotationCornerMultiplier;
    } else {
      return 0.0;
    }
  }

  //handle the card rotation about a point
  Offset _rotationOrigin(Rect dragBounds) {
    if (dragStart != null) {
      return dragStart - dragBounds.topLeft;
    } else {
      return const Offset(0.0, 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildCardStack();
  }

  //build card stack
  Widget _buildCardStack() {
    return new AnchoredOverlay(
      showOverlay: true,
      child: new Container(),
      overlayBuilder: (context, anchorBounds, anchor) {
        return CenterAbout(
          position: anchor,
          child: new Transform(
            transform:
                new Matrix4.translationValues(cardOffset.dx, cardOffset.dy, 0.0)
                  ..rotateZ(_rotation(anchorBounds)),
            origin: _rotationOrigin(anchorBounds),
            child: new Container(
              key: profileCardKey,
              width: anchorBounds.width,
              height: anchorBounds.height,
              padding: const EdgeInsets.all(16.0),
              child: new GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: widget.card),
            ),
          ),
        );
      },
    );
  }
}
