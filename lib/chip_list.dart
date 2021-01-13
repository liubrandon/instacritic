import 'package:flutter/material.dart';
import 'package:instacritic/constants.dart';
import 'package:instacritic/tag.dart';
import 'package:provider/provider.dart';
import 'instagram_repository.dart';

void clearCurrTag() => selectedTagIndex= -1;

class ChipList extends StatefulWidget {
  final void Function(String, {Tag tag}) updateCurrentReviews;
  final TextEditingController textController;
  const ChipList(this.updateCurrentReviews, this.textController);
  @override
  _ChipListState createState() => _ChipListState();
}

int selectedTagIndex = -1;
class _ChipListState extends State<ChipList> {
  @override
  Widget build(BuildContext context) {
    List<Tag> tags = Provider.of<InstagramRepository>(context,listen:false).allTagsSorted.keys.toList();
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        const SizedBox(width: 15),
        for(int i = 0; i < tags.length; i++)
          _buildChip(tags[i], i),
        const SizedBox(width: 15),
      ],
    );
  }
  Widget _buildChip(Tag tag, int index) {
    bool selected = index == selectedTagIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        elevation: 3,
        label: Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Text(tag.displayName, style: TextStyle(
            color: selected ? Colors.white : Colors.black, 
            fontWeight: FontWeight.w500
            ),
          )
        ),
        selected: selected,
        onSelected: (bool selected) {
          setState(() {
            if(selected) {
              selectedTagIndex = index;
              widget.updateCurrentReviews('', tag: tag);
              widget.textController.text = tag.displayName;
            }
            // else {
            //   _selectedTagIndex = -1;
            //   widget.textController.text = '';
            // }
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Constants.myPurple,
      ),
    );
  }
}