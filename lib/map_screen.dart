
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:instacritic/chip_list.dart';
import 'package:instacritic/constants.dart';
import 'package:instacritic/map_layer.dart';
import 'package:instacritic/tag.dart';

class MapScreen extends StatefulWidget {
  final TabController tabController;
  final TextEditingController textController;
  final FocusNode searchBoxFocusNode;
  final void Function(String, {Tag tag}) updateCurrentReviews;
  final void Function() clearSearchText;
  const MapScreen(this.tabController, this.textController, this.searchBoxFocusNode, this.updateCurrentReviews, this.clearSearchText);
  @override _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with AutomaticKeepAliveClientMixin {
  ScrollController _scrollController;
  bool isMobile;
  @override bool get wantKeepAlive => true; // Used to keep tab alive
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    isMobile = MediaQuery.of(context).size.width < Constants.mobileWidth;
    return Stack(
      children: [
        MapLayer(),
        if(isMobile)
          Column(
            children: [
              _buildSearchBar(),
              _buildTagChips(),
            ],
          ),
        if(!isMobile)
          Row(
            children: [
              _buildSearchBar(),
              _buildTagChips(),
            ],
          )
      ]
    );
  }

  Widget _buildTagChips() {
    return Expanded(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(top: isMobile ? 72 : 19),
          child: Container(
            height: 40,
            child: ChipList(widget.updateCurrentReviews, widget.textController, _scrollController),
          ),
        )
      ),
    );
  }

  Widget _buildSearchBar() {
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
                        Spacer(),
                        (widget.textController.text.length > 0) ? Padding(
                          padding: EdgeInsets.only(right: 5),
                          child: IconButton(
                            icon: Icon(Icons.clear, size: 17, color: Colors.grey),
                            color:  Colors.black,
                            focusColor: Colors.transparent, hoverColor: Colors.transparent, highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onPressed: widget.clearSearchText, 
                          )
                        ) : Container(),
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