import 'package:flutter/foundation.dart';

class GStatus {
  static const _error = "error";
  static const _reserved = "reserved";
  static const _notReserved = "not reserved";

  String value;
  GStatus(String s) {
    value = s;
  }

  factory GStatus.error() {
    return GStatus(GStatus._error);
  }
  factory GStatus.reserved() {
    return GStatus(GStatus._reserved);
  }
  factory GStatus.notReserved() {
    return GStatus(GStatus._notReserved);
  }

  @override
  bool operator ==(other) => hashCode == other.hashCode;

  @override
  int get hashCode => value.hashCode;

}

abstract class GScrapperResponse<ScrapperStatus extends GStatus> {
  ScrapperStatus status;
  String id;
  String countryCode;
  String landline;
  String errorMessage = "";
  String comment = "";

  Map<String, dynamic> extras = {};

  GScrapperResponse({
    @required this.status,
    @required this.id,
    @required this.countryCode,
    @required this.landline,
    this.errorMessage,
    this.comment,
    this.extras,
  });

  String get name;
}

abstract class GScrapper<ScrapperResponse extends GScrapperResponse> {
  Future<ScrapperResponse> scrape(String landlineID, String code, String phone);
  Future<void> waitPreferedTime();
}
