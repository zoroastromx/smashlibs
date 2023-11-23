part of smashlibs;

class SketchPage extends StatefulWidget {
  @override
  _SketchPageState createState() => new _SketchPageState();
}

class _SketchPageState extends State<SketchPage> {
  bool _finished = false;
  PainterController _controller = _newController();

  @override
  void initState() {
    super.initState();
  }

  static PainterController _newController() {
    PainterController controller = new PainterController();
    controller.thickness = 5.0;
    controller.backgroundColor = Colors.white;
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actions;
    if (_finished) {
      actions = <Widget>[
        new IconButton(
          icon: new Icon(Icons.content_copy),
          tooltip: SLL.of(context).form_sketch_newSketch,
          onPressed: () => setState(() {
            _finished = false;
            _controller = _newController();
          }),
        ),
      ];
    } else {
      actions = <Widget>[
        new IconButton(
            icon: new Icon(
              Icons.undo,
            ),
            tooltip: SLL.of(context).form_sketch_undo,
            onPressed: () {
              if (_controller.isEmpty) {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) =>
                        new Text(SLL.of(context).form_sketch_noUndo));
              } else {
                _controller.undo();
              }
            }),
        new IconButton(
            icon: new Icon(Icons.delete),
            tooltip: SLL.of(context).form_sketch_clear,
            onPressed: _controller.clear),
        new IconButton(
          icon: new Icon(Icons.check),
          tooltip: SLL.of(context).form_sketch_save,
          onPressed: () => Navigator.pop(context, _controller.finish().toPNG()),
        ) //_show(_controller.finish(), context)),
      ];
    }
    return new Scaffold(
      appBar: new AppBar(
          title: Text(SLL.of(context).form_sketch_sketcher),
          actions: actions,
          bottom: new PreferredSize(
            child: new DrawBar(_controller),
            preferredSize: new Size(MediaQuery.of(context).size.width, 30.0),
          )),
      body: new Center(
          child: new AspectRatio(
              aspectRatio: 1.0, child: new Painter(_controller))),
    );
  }
}

class DrawBar extends StatelessWidget {
  final PainterController _controller;

  DrawBar(this._controller);

  @override
  Widget build(BuildContext context) {
    return new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Flexible(child: new StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return new Container(
              child: new Slider(
            value: _controller.thickness,
            onChanged: (double value) => setState(() {
              _controller.thickness = value;
            }),
            min: 1.0,
            max: 20.0,
            activeColor: Colors.white,
          ));
        })),
        new StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return IconButton(
              icon: new Icon(
                _controller.eraseMode ? MdiIcons.eraser : MdiIcons.pencil,
                color: SmashColors.mainBackground,
              ),
              tooltip: _controller.eraseMode
                  ? SLL.of(context).form_sketch_enableDrawing
                  : SLL.of(context).form_sketch_enableEraser,
              onPressed: () {
                setState(() {
                  _controller.eraseMode = !_controller.eraseMode;
                });
              });
        }),
        new ColorPickerButton(_controller.backgroundColor, (newColor) {
          _controller.backgroundColor = newColor;
        }),
        new ColorPickerButton(_controller.drawColor, (newColor) {
          _controller.drawColor = newColor;
        }),
      ],
    );
  }
}

// class SketchColorPickerButton extends StatefulWidget {
//   final PainterController _controller;
//   final bool _background;

//   SketchColorPickerButton(this._controller, this._background);

//   @override
//   _SketchColorPickerButtonState createState() =>
//       new _SketchColorPickerButtonState();
// }

// class _SketchColorPickerButtonState extends State<SketchColorPickerButton> {
//   @override
//   Widget build(BuildContext context) {
//     return new IconButton(
//         icon: new Icon(_iconData, color: _color),
//         tooltip: widget._background
//             ? SLL.of(context).form_sketch_backColor
//             : SLL.of(context).form_sketch_strokeColor,
//         onPressed: _pickColor);
//   }

//   void _pickColor() {
//     Color pickerColor = _color;
//     Navigator.of(context)
//         .push(new MaterialPageRoute(
//             fullscreenDialog: true,
//             builder: (BuildContext context) {
//               return new Scaffold(
//                   appBar: new AppBar(
//                     title: Text(SLL.of(context).form_sketch_pickColor),
//                   ),
//                   body: new Container(
//                       alignment: Alignment.center,
//                       child: new ColorPicker(
//                         pickerColor: pickerColor,
//                         onColorChanged: (Color c) => pickerColor = c,
//                       )));
//             }))
//         .then((_) {
//       setState(() {
//         _color = pickerColor;
//       });
//     });
//   }

//   Color get _color => widget._background
//       ? widget._controller.backgroundColor
//       : widget._controller.drawColor;

//   IconData get _iconData =>
//       widget._background ? Icons.format_color_fill : Icons.brush;

//   set _color(Color color) {
//     if (widget._background) {
//       widget._controller.backgroundColor = color;
//     } else {
//       widget._controller.drawColor = color;
//     }
//   }
// }
