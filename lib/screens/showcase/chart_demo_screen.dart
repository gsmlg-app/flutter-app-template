import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_chart/app_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';

class ChartDemoScreen extends StatefulWidget {
  static const name = 'Chart Demo';
  static const path = 'chart';

  const ChartDemoScreen({super.key});

  @override
  State<ChartDemoScreen> createState() => _ChartDemoScreenState();
}

class _ChartDemoScreenState extends State<ChartDemoScreen> {
  // Sample data for line chart
  final List<ChartDataPoint> lineData = [
    const ChartDataPoint(0, 30),
    const ChartDataPoint(1, 50),
    const ChartDataPoint(2, 35),
    const ChartDataPoint(3, 70),
    const ChartDataPoint(4, 55),
    const ChartDataPoint(5, 80),
    const ChartDataPoint(6, 65),
  ];

  // Sample data for bar chart
  final List<CategoryDataPoint> barData = [
    const CategoryDataPoint(label: 'Mon', value: 35),
    const CategoryDataPoint(label: 'Tue', value: 28),
    const CategoryDataPoint(label: 'Wed', value: 45),
    const CategoryDataPoint(label: 'Thu', value: 60),
    const CategoryDataPoint(label: 'Fri', value: 52),
  ];

  // Sample data for pie chart
  final List<CategoryDataPoint> pieData = [
    CategoryDataPoint(label: 'Mobile', value: 45, color: Colors.blue),
    CategoryDataPoint(label: 'Desktop', value: 30, color: Colors.green),
    CategoryDataPoint(label: 'Tablet', value: 15, color: Colors.orange),
    CategoryDataPoint(label: 'Other', value: 10, color: Colors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(
        const Key(ShowcaseScreen.name),
        context,
      ),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      body: (context) {
        return SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(title: Text(ChartDemoScreen.name)),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSection(
                      context,
                      title: 'SimpleLineChart',
                      description: 'Line and area charts with smooth curves',
                      children: [
                        _buildChartCard(
                          context,
                          title: 'Basic Line Chart',
                          height: 200,
                          child: SimpleLineChart(
                            data: lineData,
                            lineColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildChartCard(
                          context,
                          title: 'Area Chart with Fill',
                          height: 200,
                          child: SimpleLineChart(
                            data: lineData,
                            lineColor: Theme.of(context).colorScheme.tertiary,
                            fillArea: true,
                            showPoints: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSection(
                      context,
                      title: 'SimpleBarChart',
                      description: 'Vertical and horizontal bar charts',
                      children: [
                        _buildChartCard(
                          context,
                          title: 'Vertical Bar Chart',
                          height: 220,
                          child: SimpleBarChart(data: barData),
                        ),
                        const SizedBox(height: 16),
                        _buildChartCard(
                          context,
                          title: 'Horizontal Bar Chart',
                          height: 200,
                          child: SimpleBarChart(
                            data: barData,
                            horizontal: true,
                            padding: const EdgeInsets.fromLTRB(48, 24, 24, 24),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSection(
                      context,
                      title: 'SimplePieChart',
                      description: 'Pie and donut charts with labels',
                      children: [
                        _buildChartCard(
                          context,
                          title: 'Pie Chart',
                          height: 250,
                          child: SimplePieChart(data: pieData),
                        ),
                        const SizedBox(height: 16),
                        _buildChartCard(
                          context,
                          title: 'Donut Chart',
                          height: 250,
                          child: SimplePieChart(
                            data: pieData,
                            innerRadiusRatio: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildChartCard(
    BuildContext context, {
    required String title,
    required double height,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(height: height, child: child),
          ],
        ),
      ),
    );
  }
}
