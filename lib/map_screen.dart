
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:instacritic/chip_list.dart';
import 'package:instacritic/map_layer.dart';
import 'package:instacritic/tag.dart';

class MapScreen extends StatefulWidget {
  final TabController tabController;
  final TextEditingController textController;
  final FocusNode searchBoxFocusNode;
  final void Function(String, {Tag tag}) updateCurrentReviews;
  const MapScreen(this.tabController, this.textController, this.searchBoxFocusNode, this.updateCurrentReviews);
  @override _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true; // Used to keep tab alive

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        MapLayer(),
        _buildSearchBar(),
        _buildTagChips(),
      ]
    );
  }

  Widget _buildTagChips() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 72),
        child: Container(
          height: 25,
          child: ChipList(widget.updateCurrentReviews, widget.textController),
        ),
      )
    );
  }

  Widget _buildSearchBar() {
    double mobileWidth = 500;
    bool isMobile = MediaQuery.of(context).size.width < mobileWidth;
    final borderRadius = BorderRadius.circular(15.0);
    return Align(
      alignment: isMobile ? Alignment.topCenter : Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(top: 15, left: isMobile ? 0 : 15),
        child: GestureDetector(
          child: Container(
            width: isMobile ? MediaQuery.of(context).size.width - 30 : 400,
            height: 48,
            child: Material(
              color: Colors.white,
              elevation: 3.0,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 14.0),
                      child: Icon(Icons.search, color: Colors.grey[600]),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        widget.textController.text.isEmpty ? 'Search' : widget.textController.text, 
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 16,
                          color: widget.textController.text.isEmpty ? Colors.grey[600] : Colors.black,
                        ),
                      ),
                    ),
                  ]
                ),
            ),
          ),
          onTap: () {
            FocusScope.of(context).requestFocus(widget.searchBoxFocusNode);
            widget.tabController.animateTo(0);
            widget.textController.selection = TextSelection(baseOffset: widget.textController.text.length, extentOffset: widget.textController.text.length);
          },
        ),
      ),
    );
  }
}