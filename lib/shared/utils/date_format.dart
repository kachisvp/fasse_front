import 'package:intl/intl.dart';

final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');
final DateFormat _isoDateTimeFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

/// JST固定のISO8601日付文字列（例: 2026-07-13）に変換する。
String formatIsoDate(DateTime date) => _isoDateFormat.format(date);

DateTime parseIsoDate(String date) => _isoDateFormat.parseStrict(date);

/// JST固定のISO8601日時文字列（例: 2026-07-13T19:30:00+09:00）に変換する。
String formatIsoDateTime(DateTime dateTime) => '${_isoDateTimeFormat.format(dateTime)}+09:00';

DateTime parseIsoDateTime(String dateTime) =>
    _isoDateTimeFormat.parseStrict(dateTime.replaceFirst(RegExp(r'[+-]\d\d:\d\d$'), ''));
