import 'package:flutter/material.dart';
import 'package:instacritic/instagram_repository.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'constants.dart';

class ChartScreen extends StatefulWidget {
  final TextEditingController textController;
  const ChartScreen(this.textController);
  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int touchedIndex;

  @override
  Widget build(BuildContext context) {
    int numShown = Provider.of<InstagramRepository>(context).numReviewsShown;
    int numTotal = Provider.of<InstagramRepository>(context).totalNumReviews;
    List<int> allNumStars = Provider.of<InstagramRepository>(context).allNumStars;
    List<int> shownNumStars = Provider.of<InstagramRepository>(context).currNumStars;
    List<PercentData> shownPercents = [null,null,null,null,null];
    List<PercentData> allPercents = [null,null,null,null,null];
    List<String> labels = ['💀','⭐️','⭐️⭐️','⭐️⭐️⭐️','⭐️⭐️⭐️⭐️',];
    for(int i = 0; i < 5; i++) {
      if(numTotal != 0)
        allPercents[(i+9)%5] = (PercentData(number: allNumStars[i], percent: format((allNumStars[i]/numTotal)*100.0), label: labels[i]));  
      if(numShown != 0)
        shownPercents[(i+9)%5] = (PercentData(number: shownNumStars[i], percent: format((shownNumStars[i]/numShown)*100.0), label: labels[i]));  
    }
    String searchQuery = widget.textController.text;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height:12),
                if(numTotal != 0)
                  _buildPieChart('$numTotal total ratings', allPercents),
                if(numTotal == 0)
                  Text('No ratings loaded'),
                const SizedBox(height:12),
                if(numShown != 0 && numShown != numTotal)
                  _buildPieChart("$numShown review${numShown != 1 ? 's' : ''} matching '$searchQuery'", shownPercents),  
                if(numShown == 0)
                  Text('No search results'),
                if(numShown != 0 && numShown == numTotal) 
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Text('Search and return to this screen to see specific breakdowns', textAlign: TextAlign.center,),
                  ),
                const SizedBox(height:12),
              ]
            )
          ),
        ],
      ),
    );
  }

  Container _buildPieChart(String title, List<PercentData> percents) {
    return Container(
      child: SfCircularChart(
        title: ChartTitle(text: title),
        series: _getDoughnutSeries(percents),
        tooltipBehavior: TooltipBehavior(enable: true, format: 'point.x total, point.y%'),
      ),
    );
  }

  List<DoughnutSeries<PercentData, String>> _getDoughnutSeries(List<PercentData> data) {
    return [
      DoughnutSeries<PercentData, String>(
        dataSource: data.reversed.toList(),
        xValueMapper: (PercentData datum, _) => datum.number.toString(),
        yValueMapper: (PercentData datum, _) => datum.percent,
        dataLabelMapper: (PercentData datum, _) => datum.label,
        radius: '80%',
        explode: true,
        explodeOffset: '10%',
        dataLabelSettings: DataLabelSettings(
            isVisible: true,
            showZeroValue: false,
            labelPosition: ChartDataLabelPosition.outside,
            connectorLineSettings: ConnectorLineSettings(type: ConnectorType.curve),
            labelIntersectAction: LabelIntersectAction.none,
        )
      )
    ];
  }

  double format(double n) => double.parse(n.toStringAsFixed(n.round() == n ? 0 : 2));
  
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
              elevation: 0,
              pinned: true,
              title: Text(Provider.of<InstagramRepository>(context,listen:false).igUsername + '\'s ratings'),
              toolbarHeight: 48,
              backgroundColor: Constants.myPurple,
            );
  }
}

class PercentData {
  final String label;
  final double percent;
  final int number;
  const PercentData({this.label, this.percent, this.number});
}