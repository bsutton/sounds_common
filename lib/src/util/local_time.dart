/*
 * This file is part of Sounds.
 *
 *   Sounds is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Sounds is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Sounds.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:meta/meta.dart';

import 'format.dart';
import 'local_date.dart';

/// Provides a class which wraps a DateTime but just supplies
/// the time component.
/// The hour component uses a 24 hour clock.
@immutable
class LocalTime {
  ///
  final int hour;

  ///
  final int minute;

  ///
  final int second;

  ///
  const LocalTime({required this.hour, required this.minute, this.second = 0});

  ///
  LocalTime.fromDateTime(DateTime dateTime)
      : hour = dateTime.hour,
        minute = dateTime.minute,
        second = dateTime.second;

  ///
  DateTime toDateTime() {
    var now = DateTime.now();

    return DateTime(now.year, now.month, now.day, hour, minute, second);
  }

  ///
  static DateTime stripDate(DateTime dateTime) {
    return DateTime(0, 0, 0, dateTime.hour, dateTime.minute, dateTime.second,
        dateTime.millisecond, dateTime.microsecond);
  }

  ///
  static LocalTime now() {
    var now = DateTime.now();

    return LocalTime(hour: now.hour, minute: now.minute, second: now.second);
  }

  ///
  LocalTime addDuration(Duration duration) {
    return LocalTime.fromDateTime(toDateTime().add(duration));
  }

  ///
  bool isAfter(LocalTime rhs) {
    return hour > rhs.hour ||
        (hour == rhs.hour && minute > rhs.minute) ||
        (hour == rhs.hour && minute == rhs.minute && second > rhs.second);
  }

  ///
  bool isAfterOrEqual(LocalTime rhs) {
    return isAfter(rhs) || isEqual(rhs);
  }

  ///
  bool isBefore(LocalTime rhs) {
    return !isAfter(rhs) && !isEqual(rhs);
  }

  ///
  bool isBeforeOrEqual(LocalTime rhs) {
    return isBefore(rhs) || isEqual(rhs);
  }

  ///
  bool isEqual(LocalTime rhs) {
    return hour == rhs.hour && minute == rhs.minute && second == rhs.second;
  }

  ///
  DateTime atDate(LocalDate date) {
    return DateTime(date.year, date.month, date.day, hour, minute, second);
  }

  @override
  String toString() {
    return Format.localTime(this);
  }
}
