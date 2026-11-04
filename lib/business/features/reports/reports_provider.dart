import 'package:admivida/business/features/reports/models/business_report_model.dart';
import 'package:admivida/business/features/reports/reports_service.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reports_provider.g.dart';

enum ReportPeriodFilter {
  today('Hoy'),
  thisWeek('Esta semana'),
  thisMonth('Este mes'),
  custom('Personalizado');

  final String label;
  const ReportPeriodFilter(this.label);
}

class ReportFilterState {
  final ReportPeriodFilter filter;
  final DateTimeRange? customRange;

  const ReportFilterState({
    this.filter = ReportPeriodFilter.thisMonth,
    this.customRange,
  });

  ReportFilterState copyWith({
    ReportPeriodFilter? filter,
    DateTimeRange? customRange,
  }) {
    return ReportFilterState(
      filter: filter ?? this.filter,
      customRange: customRange ?? this.customRange,
    );
  }
}

@riverpod
class ReportFilter extends _$ReportFilter {
  @override
  ReportFilterState build(String businessId) => const ReportFilterState();

  void setFilter(ReportPeriodFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setCustomRange(DateTimeRange range) {
    state = state.copyWith(filter: ReportPeriodFilter.custom, customRange: range);
  }
}

@riverpod
Future<BusinessReportModel> businessReport(Ref ref, String businessId) async {
  final filterState = ref.watch(reportFilterProvider(businessId));

  final dates = _calculateDates(filterState);
  final result = await ReportsService.getBusinessOverviewReport(
    businessId: businessId,
    startDate: dates.startDate,
    endDate: dates.endDate,
    tzOffset: dates.tzOffset,
  );

  return result.when(
    (failure) => throw failure,
    (report) => report,
  );
}

class DateRangeStrings {
  final String startDate;
  final String endDate;
  final int tzOffset;

  DateRangeStrings({
    required this.startDate,
    required this.endDate,
    required this.tzOffset,
  });
}

DateRangeStrings _calculateDates(ReportFilterState filterState) {
  final now = DateTime.now();
  final tzOffset = now.timeZoneOffset.inMinutes;

  DateTime localStart;
  DateTime localEnd;

  switch (filterState.filter) {
    case ReportPeriodFilter.today:
      localStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
      localEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      break;

    case ReportPeriodFilter.thisWeek:
      // Lunes de la semana actual a las 00:00:00
      final monday = now.subtract(Duration(days: now.weekday - 1));
      localStart = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
      localEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      break;

    case ReportPeriodFilter.thisMonth:
      // Primer día del mes a las 00:00:00
      localStart = DateTime(now.year, now.month, 1, 0, 0, 0);
      localEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      break;

    case ReportPeriodFilter.custom:
      if (filterState.customRange != null) {
        final start = filterState.customRange!.start;
        final end = filterState.customRange!.end;
        localStart = DateTime(start.year, start.month, start.day, 0, 0, 0);
        localEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
      } else {
        localStart = DateTime(now.year, now.month, 1, 0, 0, 0);
        localEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      }
      break;
  }

  // Convertimos las fechas locales exactas a UTC para que coincidan con la base de datos en UTC
  return DateRangeStrings(
    startDate: localStart.toUtc().toIso8601String(),
    endDate: localEnd.toUtc().toIso8601String(),
    tzOffset: tzOffset,
  );
}
