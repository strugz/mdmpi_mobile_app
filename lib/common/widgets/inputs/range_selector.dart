import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:mdmpi_mobile_app/base/utils/formatters/formatters.dart';

/// Dual-thumb range selector with badges above each thumb showing formatted values.
/// Designed to be reusable across features. Badges attempt to follow thumb positions.
class RangeSelector extends StatefulWidget {
  const RangeSelector({
	super.key,
	required this.min,
	required this.max,
	required this.values,
	required this.onChanged,
	this.onChangeEnd,
	this.divisions,
	this.labelFormatter,
  });

  final double min;
  final double max;
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;
  final ValueChanged<RangeValues>? onChangeEnd;
  final int? divisions;
  final String Function(double)? labelFormatter;

  @override
  State<RangeSelector> createState() => _RangeSelectorState();
}

class _RangeSelectorState extends State<RangeSelector> {
  late RangeValues _localValues;

  @override
  void initState() {
	super.initState();
	_localValues = widget.values;
  }

  @override
  void didUpdateWidget(covariant RangeSelector oldWidget) {
	super.didUpdateWidget(oldWidget);
	if (oldWidget.values != widget.values) _localValues = widget.values;
  }

  String _format(double v) => widget.labelFormatter?.call(v) ?? BFormatter.formatPesoCurrency(v);

  @override
  Widget build(BuildContext context) {
	return LayoutBuilder(builder: (context, constraints) {
	  final width = constraints.maxWidth;

	  double posFor(double value) {
		if (widget.max - widget.min == 0) return 0;
		final frac = (value - widget.min) / (widget.max - widget.min);
		return (frac.clamp(0.0, 1.0) * width);
	  }

	  const badgeWidth = 92.0;

	  return Column(
		crossAxisAlignment: CrossAxisAlignment.start,
		children: [
		  SizedBox(
			height: 40,
			child: Stack(children: [
			  // Start badge
			  Positioned(
				left: (posFor(_localValues.start) - badgeWidth / 2).clamp(0.0, width - badgeWidth),
				top: 0,
				child: Container(
				  width: badgeWidth,
				  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
				  decoration: BoxDecoration(color: BColors.primary, borderRadius: BorderRadius.circular(8)),
				  child: Center(
					child: Text(_format(_localValues.start),
						style: const TextStyle(color: BColors.white, fontWeight: FontWeight.bold, fontSize: 12)),
				  ),
				),
			  ),
			  // End badge
			  Positioned(
				left: (posFor(_localValues.end) - badgeWidth / 2).clamp(0.0, width - badgeWidth),
				top: 0,
				child: Container(
				  width: badgeWidth,
				  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
				  decoration: BoxDecoration(color: BColors.primary, borderRadius: BorderRadius.circular(8)),
				  child: Center(
					child: Text(_format(_localValues.end),
						style: const TextStyle(color: BColors.white, fontWeight: FontWeight.bold, fontSize: 12)),
				  ),
				),
			  ),
			]),
		  ),
		  const SizedBox(height: BSizes.xs),
		  RangeSlider(
			min: widget.min,
			max: widget.max,
			values: _localValues,
			divisions: widget.divisions,
			labels: RangeLabels(_format(_localValues.start), _format(_localValues.end)),
			onChanged: (v) {
			  setState(() => _localValues = v);
			  widget.onChanged(v);
			},
			onChangeEnd: (v) => widget.onChangeEnd?.call(v),
		  ),
		],
	  );
	});
  }
}


