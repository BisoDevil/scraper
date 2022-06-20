import 'package:flutter/cupertino.dart';
import 'package:get/get_connect.dart';
import 'package:scraper/app/data/common.dart';
import 'package:scraper/io/logger.dart';

class OrangeStatus extends GStatus {
  OrangeStatus(String s) : super(s);
  OrangeStatus.of(GStatus s): this(s.value);
}

class OrangeResponse extends GScrapperResponse<OrangeStatus> {
  OrangeResponse({
    @required OrangeStatus status,
    @required String id,
    @required String countryCode,
    @required String landline,
    String errorMessage,
    String comment,
    Map<String, dynamic> extras,
  }) : super(
          countryCode: countryCode,
          id: id,
          landline: landline,
          status: status,
          comment: comment,
          errorMessage: errorMessage,
          extras: extras,
        );
  @override
  String get name => "Orange";
}

/// Ardy scrapping
class OrangeScrapper extends GScrapper<OrangeResponse> {
  static final OrangeScrapper _instance = OrangeScrapper._internal();

  static const defaultTimeOutSeconds = 30;
  int confidenceTrials = 3;
  factory OrangeScrapper() {
    return _instance;
  }
  OrangeScrapper._internal();

  void init({int confidenceTrials = 3}) {
    this.confidenceTrials = confidenceTrials;
  }

  int id = 1;

  @override
  Future<OrangeResponse> scrape(
      String landlineID, String code, String phone) async {
    String currentId = landlineID ?? (id++).toString();
    var res = await _scrape(currentId, code, phone);
    var trials = confidenceTrials - 1;
    while (trials > 0) {
      if (res.status != GStatus.notReserved()) {
        break;
      }
      print("orange - make confidence reamaining $trials");
      RunLogger().newLine(">$landlineID orange - make confidence reamaining $trials");
      res = await _scrape(currentId, code, phone);
      trials -= 1;
    }
    return res;
  }

  Future<OrangeResponse> _scrape(
    String currentId,
    String code,
    String phone,
  ) async {
    var resContent = "";
    try {
      var res = await _request(code, phone);
      resContent = res.bodyString;
      if (resContent == null) {
        RunLogger().newLine(">$currentId orange - rescontent is null, status code = ${res.statusCode}");
        return OrangeResponse(
          status: OrangeStatus.of(GStatus.error()),
          id: currentId,
          countryCode: code,
          landline: phone,
          comment: "rescontent is null",
          errorMessage:
              "status text = ${res.statusText}. status code = ${res.statusCode}",
        );
      }
      // first we should check for new landline number
      if (resContent.contains(
          "The service is temporarily unavailable. Please try again later")) {
        return OrangeResponse(
          countryCode: code,
          id: currentId,
          landline: phone,
          comment:
              "The service is temporarily unavailable. Please try again later",
          status: OrangeStatus.of(GStatus.notReserved()),
        );
      }
      bool isNoBill =
          resContent.contains("Thank you, no payments are currently due");
      bool hasBill = resContent.contains("Invoice Due Date");
      RunLogger().newLine(">$currentId hasBill=$hasBill, isNoBill=$isNoBill");
      return OrangeResponse(
        countryCode: code,
        id: currentId,
        landline: phone,
        comment: (isNoBill ^ hasBill) ? "" : "Check manually !",
        extras: {"hasBill": hasBill, "isNoBill": isNoBill},
        status: OrangeStatus.of(GStatus.reserved()),
      );
    } catch (e, s) {
      print(e.toString());
      RunLogger().newLine(">$currentId #orange error: $e while resContent=$resContent with stacktrace $s");
      return OrangeResponse(
        id: currentId,
        countryCode: code,
        landline: phone,
        status: OrangeStatus.of(GStatus.error()),
        errorMessage: "error: " + e.toString(),
      );
    }
  }

  Future<Response> _request(String code, String phone) async {
    GetHttpClient client = GetHttpClient(
      timeout: Duration(seconds: defaultTimeOutSeconds),
      allowAutoSignedCert: true,
    );
    return client.post('https://dsl.orange.eg/en/myaccount/pay-bill',
        headers: {
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
          'Accept-Language': 'en-US,en;q=0.9',
          'Cache-Control': 'max-age=0',
          'Connection': 'keep-alive',
          'Origin': 'https://dsl.orange.eg',
          'Referer': 'https://dsl.orange.eg/en/myaccount/pay-bill',
          'Sec-Fetch-Dest': 'document',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Site': 'same-origin',
          'Sec-Fetch-User': '?1',
          'Sec-GPC': '1',
          'Upgrade-Insecure-Requests': '1',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.54 Safari/537.36',
        },
        body: FormData({
          '_wpcmWpid': '',
          'wpcmVal': '',
          'MSOWebPartPage_PostbackSource': '',
          'MSOTlPn_SelectedWpId': '',
          'MSOTlPn_View': '0',
          'MSOTlPn_ShowSettings': 'False',
          'MSOGallery_SelectedLibrary': '',
          'MSOGallery_FilterString': '',
          'MSOTlPn_Button': 'none',
          '__EVENTTARGET': '',
          '__EVENTARGUMENT': '',
          '__REQUESTDIGEST':
              '0xA234AB9A9BCF97F37C6849670C95EE47AB05CF0C7E27E06C065994612FEDDF46F033385481D5714CCBEA042739B12C2F131281CBF38B54645DCE8CD6EDC88D37,13 May 2022 17:13:56 -0000',
          'MSOSPWebPartManager_DisplayModeName': 'Browse',
          'MSOSPWebPartManager_ExitingDesignMode': 'false',
          'MSOWebPartPage_Shared': '',
          'MSOLayout_LayoutChanges': '',
          'MSOLayout_InDesignMode': '',
          '_wpSelected': '',
          '_wzSelected': '',
          'MSOSPWebPartManager_OldDisplayModeName': 'Browse',
          'MSOSPWebPartManager_StartWebPartEditingName': 'false',
          'MSOSPWebPartManager_EndWebPartEditing': 'false',
          '__VIEWSTATE':
              '/wEPDwUBMA9kFgJmD2QWAgIBD2QWBgIBD2QWAgIHD2QWAmYPFgIeBFRleHQFKlBheSBteSBpbnRlcm5ldCBiaWxsIG9ubGluZSB8IE9yYW5nZSBFZ3lwdGQCBQ9kFgoCAg9kFgICAQ9kFgIFJmdfMzc1NWJkYTNfMDU1ZF80MGZkXzk4MzVfMjNlY2M2ZmYyMjA3D2QWAmYPZBYEAgQPFgIeB1Zpc2libGVnZAIGD2QWAgIBDzwrABECARAWABYAFgAMFCsAAGQCBg9kFgICAQ9kFgICAg9kFgICBQ9kFgICAw8WAh8BaBYCZg9kFgQCAg9kFgYCAQ8WAh8BaGQCAw8WAh8BaGQCBQ8WAh8BaGQCAw8PFgIeCUFjY2Vzc0tleQUBL2RkAg4PZBYMAgIPFgIeC18hSXRlbUNvdW50AgMWBmYPZBYCAgEPZBYEAgEPDxYEHwAFBFNob3AeC05hdmlnYXRlVXJsZWRkAgMPZBYGAgEPDxYGHwAFBFNob3AfBAUULy9zaG9wLm9yYW5nZS5lZy9lbi8eB1Rvb2xUaXAFBFNob3BkZAIDDxYCHwMCBBYIZg9kFgICAw9kFgQCAQ8PFgYfBAUnLy9zaG9wLm9yYW5nZS5lZy9lbi9tb2JpbGVzLWFuZC1kZXZpY2VzHwAFEU1vYmlsZXMgJiBEZXZpY2VzHwUFEU1vYmlsZXMgJiBEZXZpY2VzZGQCAw9kFgICAQ8WAh8DAgYWDGYPZBYCAgEPDxYGHwQFHC8vc2hvcC5vcmFuZ2UuZWcvZW4vbW9iaWxlcy8fAAUHTW9iaWxlcx8FBQdNb2JpbGVzZGQCAQ9kFgICAQ8PFgYfBAUtaHR0cHM6Ly9zaG9wLm9yYW5nZS5lZy9lbi9kZXZpY2VzL2FjY2Vzc29yaWVzHwAFC0FjY2Vzc29yaWVzHwUFC0FjY2Vzc29yaWVzZGQCAg9kFgICAQ8PFgYfBAUjLy9zaG9wLm9yYW5nZS5lZy9lbi9kZXZpY2VzL3RhYmxldHMfAAUHVGFibGV0cx8FBQdUYWJsZXRzZGQCAw9kFgICAQ8PFgYfBAUqaHR0cHM6Ly9zaG9wLm9yYW5nZS5lZy9lbi9kZXZpY2VzL3NtYXJ0LXR2HwAFCVNtYXJ0IFRWcx8FBQlTbWFydCBUVnNkZAIED2QWAgIBDw8WBh8EBSMvL3Nob3Aub3JhbmdlLmVnL2VuL2RldmljZXMvcm91dGVycx8ABQdSb3V0ZXJzHwUFB1JvdXRlcnNkZAIFD2QWAgIBDw8WBh8EBT5odHRwczovL3Nob3Aub3JhbmdlLmVnL2VuLzRnLW1vYmlsZXMtYW5kLWRldmljZXM/cz1jb21taW5nc29vbh8ABQ9TcGVjaWFsIE9mZmVycyAfBQUPU3BlY2lhbCBPZmZlcnMgZGQCAQ9kFgICAw9kFgQCAQ8PFgYfBAUmaHR0cHM6Ly93d3cub3JhbmdlLmVnL2VuL3RhcmlmZi1wbGFucy8fAAUMVGFyaWZmIFBsYW5zHwUFDFRhcmlmZiBQbGFuc2RkAgMPZBYCAgEPFgIfAwIEFghmD2QWAgIBDw8WBh8EBS8vL3Nob3Aub3JhbmdlLmVnL2VuL3RhcmlmZi1wbGFucy9vcmFuZ2UtcHJlbWllch8ABQhQUkVNSUVSIB8FBQhQUkVNSUVSIGRkAgEPZBYCAgEPDxYGHwQFLWh0dHBzOi8vd3d3Lm9yYW5nZS5lZy9lbi9UYXJpZmYtUGxhbnMvRlJFRW1heB8ABQdGUkVFbWF4HwUFB0ZSRUVtYXhkZAICD2QWAgIBDw8WBh8EBUtodHRwczovL3Nob3Aub3JhbmdlLmVnL2VuL3RhcmlmZi1wbGFucy9haHNhbi1uYXMtYnVuZGxlcy1hbmQtcmVjaGFyZ2UtY2FyZHMfAAURQWhzYW4gTmFzIEJ1Y2tldHMfBQURQWhzYW4gTmFzIEJ1Y2tldHNkZAIDD2QWAgIBDw8WBh8EBSQvL3Nob3Aub3JhbmdlLmVnL2VuL3RhcmlmZi1wbGFucy9hbG8fAAUDQWxvHwUFA0Fsb2RkAgIPZBYCAgMPZBYEAgEPDxYGHwQFHC8vd3d3Lm9yYW5nZS5lZy9lbi9pbnRlcm5ldC8fAAUISW50ZXJuZXQfBQUISW50ZXJuZXRkZAIDD2QWAgIBDxYCHwMCAxYGZg9kFgICAQ8PFgYfBAUrLy93d3cub3JhbmdlLmVnL2VuL2ludGVybmV0L21vYmlsZS1pbnRlcm5ldB8ABQ9Nb2JpbGUgSW50ZXJuZXQfBQUPTW9iaWxlIEludGVybmV0ZGQCAQ9kFgICAQ8PFgYfBAUTLy9kc2wub3JhbmdlLmVnL2VuLx8ABQ1Ib21lIEludGVybmV0HwUFDUhvbWUgSW50ZXJuZXRkZAICD2QWAgIBDw8WBh8EBS4vL3d3dy5vcmFuZ2UuZWcvZW4vaW50ZXJuZXQvb3JhbmdlLXRyaXBsZS1wbGF5HwAFEk9yYW5nZSBUcmlwbGUgUGxheR8FBRJPcmFuZ2UgVHJpcGxlIFBsYXlkZAIDD2QWAgIDD2QWBAIBDw8WBh8EBRwvL3d3dy5vcmFuZ2UuZWcvZW4vc2VydmljZXMvHwAFCFNlcnZpY2VzHwUFCFNlcnZpY2VzZGQCAw9kFgICAQ8WAh8DAgUWCmYPZBYCAgEPDxYGHwQFJC8vd3d3Lm9yYW5nZS5lZy9lbi9zZXJ2aWNlcy9zcGVjaWFsLx8ABQdTcGVjaWFsHwUFB1NwZWNpYWxkZAIBD2QWAgIBDw8WBh8EBSsvL3d3dy5vcmFuZ2UuZWcvZW4vc2VydmljZXMvY2FsbC1tYW5hZ2VtZW50HwAFD0NhbGwgbWFuYWdlbWVudB8FBQ9DYWxsIG1hbmFnZW1lbnRkZAICD2QWAgIBDw8WBh8EBSsvL3d3dy5vcmFuZ2UuZWcvZW4vc2VydmljZXMvc2hva3JhbiNTYWxlZm55HwAFB1NhbGVmbnkfBQUHU2FsZWZueWRkAgMPZBYCAgEPDxYGHwQFNS8vd3d3Lm9yYW5nZS5lZy9lbi9zZXJ2aWNlcy9PcmFuZ2UtZmluYW5jaWFsLXNlcnZpY2VzHwAFGU9yYW5nZSBmaW5hbmNpYWwgc2VydmljZXMfBQUZT3JhbmdlIGZpbmFuY2lhbCBzZXJ2aWNlc2RkAgQPZBYCAgEPDxYGHwQFNS8vd3d3Lm9yYW5nZS5lZy9lbi9zZXJ2aWNlcy9pbnRlcm5hdGlvbmFsLWFuZC1yb2FtaW5nHwAFGUludGVybmF0aW9uYWwgYW5kIHJvYW1pbmcfBQUZSW50ZXJuYXRpb25hbCBhbmQgcm9hbWluZ2RkAgUPZBYCAgMPFgIfAwIEFghmD2QWAgIBD2QWBgIBDw8WAh8AZWRkAgMPDxYGHwQFJ2h0dHBzOi8vd3d3Lm9yYW5nZS5lZy9lbi9lbnRlcnRhaW5tZW50Lx8ABQ1FbnRlcnRhaW5tZW50HwUFDUVudGVydGFpbm1lbnRkZAIEDxUBfzxpbWcgYWx0PSJFbnRlcnRhaW5tZW50IiBzcmM9Imh0dHBzOi8vZHNsLm9yYW5nZS5lZy9QdWJsaXNoaW5nSW1hZ2VzL01lZ2FNZW51XzEtRW50ZXJ0YWlubWVudC5qcGciIHN0eWxlPSJCT1JERVI6IDBweCBzb2xpZDsgIj5kAgEPZBYCAgEPZBYGAgEPDxYCHwBlZGQCAw8PFgYfBAUraHR0cHM6Ly93d3cub3JhbmdlLmVnL2VuL29mZmVycy1wcm9tb3Rpb25zLx8ABRNPZmZlcnMgJiBQcm9tb3Rpb25zHwUFE09mZmVycyAmIFByb21vdGlvbnNkZAIEDxUBiAE8aW1nIGFsdD0iT2ZmZXJzICZhbXA7IFByb21vdGlvbnMgIiBzcmM9Imh0dHBzOi8vZHNsLm9yYW5nZS5lZy9QdWJsaXNoaW5nSW1hZ2VzL01lZ2FNZW51XzItT2ZmZXJzUHJvbW8uanBnIiBzdHlsZT0iQk9SREVSOiAwcHggc29saWQ7ICI+ZAICD2QWAgIBD2QWBgIBDw8WAh8ABQxTdWJzY3JpYmUgdG9kZAIDDw8WBh8EBTJodHRwczovL2RzbC5vcmFuZ2UuZWcvZW4vcGFja2FnZXMvSG9tZS00Ry1QdXJjaGFzZR8ABRBIb21lIDRHIHBhY2thZ2VzHwUFEEhvbWUgNEcgcGFja2FnZXNkZAIEDxUBezxpbWcgYWx0PSJIb21lIDRHIHBhY2thZ2VzIiBzcmM9Imh0dHBzOi8vZHNsLm9yYW5nZS5lZy9QdWJsaXNoaW5nSW1hZ2VzL01lZ2FNZW51XzMtSG9tZTRHLmpwZyIgc3R5bGU9IkJPUkRFUjogMHB4IHNvbGlkOyAiPmQCAw9kFgICAQ9kFgYCAQ8PFgIfAAUDQnV5ZGQCAw8PFgYfBAUmaHR0cHM6Ly93d3cub3JhbmdlLmVnL2VuL2xpbmUtcHVyY2hhc2UfAAULT3JhbmdlIExpbmUfBQULT3JhbmdlIExpbmVkZAIEDxUBejxpbWcgYWx0PSJPcmFuZ2UgTGluZSIgc3JjPSJodHRwczovL2RzbC5vcmFuZ2UuZWcvUHVibGlzaGluZ0ltYWdlcy9NZWdhTWVudV80LU9yYW5nZUxpbmUuanBnIiBzdHlsZT0iQk9SREVSOiAwcHggc29saWQ7ICI+ZAIBD2QWAgIBD2QWBAIBDw8WBB8ABQpNeSBBY2NvdW50HwQFQy8vd3d3Lm9yYW5nZS5lZy9lbi9teWFjY291bnQvYWNjb3VudC1sb2dpbj9SZXR1cm5Vcmw9L2VuL215YWNjb3VudC8WAh4EaHJlZgVDLy93d3cub3JhbmdlLmVnL2VuL215YWNjb3VudC9hY2NvdW50LWxvZ2luP1JldHVyblVybD0vZW4vbXlhY2NvdW50L2QCAw8WAh8BaBYGAgEPDxYGHwAFCk15IEFjY291bnQfBAVDLy93d3cub3JhbmdlLmVnL2VuL215YWNjb3VudC9hY2NvdW50LWxvZ2luP1JldHVyblVybD0vZW4vbXlhY2NvdW50Lx8FBQpNeSBBY2NvdW50ZGQCAw8WAh8DAv////8PZAIFDxYCHwFoFgICAw8WAh8DAv////8PZAICD2QWAgIBD2QWBAIBDw8WBB8ABQRIZWxwHwRlZGQCAw9kFgYCAQ8PFgYfAAUESGVscB8EBRgvL3d3dy5vcmFuZ2UuZWcvZW4vaGVscC8fBQUESGVscGRkAgMPFgIfAwICFgRmD2QWAgIDD2QWBAIBDw8WBh8EBSMvL3d3dy5vcmFuZ2UuZWcvZW4vaGVscC9mYXEtbGlzdGluZx8ABRpGcmVxdWVudGx5IEFza2VkIFF1ZXN0aW9ucx8FBRpGcmVxdWVudGx5IEFza2VkIFF1ZXN0aW9uc2RkAgMPZBYCAgEPFgIfAwIEFghmD2QWAgIBDw8WBh8EBTQvL3d3dy5vcmFuZ2UuZWcvZW4vaGVscC9mYXEtZGV0YWlscz9jYXRlZ29yeT0xJlE9Mjc5HwAFMldoYXQgaXMgdGhlIG1haW4gcHJpdmlsZWdlcyBpbiBPcmFuZ2UgM0cgc2VydmljZXM/HwUFMldoYXQgaXMgdGhlIG1haW4gcHJpdmlsZWdlcyBpbiBPcmFuZ2UgM0cgc2VydmljZXM/ZGQCAQ9kFgICAQ8PFgYfBAU1Ly93d3cub3JhbmdlLmVnL2VuL2hlbHAvZmFxLWRldGFpbHM/Y2F0ZWdvcnk9MTQmUT0zMDcfAAUdV2hhdCBpcyBPcmFuZ2UgSG9tZSBJbnRlcm5ldD8fBQUdV2hhdCBpcyBPcmFuZ2UgSG9tZSBJbnRlcm5ldD9kZAICD2QWAgIBDw8WBh8EBTUvL3d3dy5vcmFuZ2UuZWcvZW4vaGVscC9mYXEtZGV0YWlscz9jYXRlZ29yeT0xNyZRPTIzOR8ABRlXaGF0IGlzIE9yYW5nZSBDYWxsIHRvbmU/HwUFGVdoYXQgaXMgT3JhbmdlIENhbGwgdG9uZT9kZAIDD2QWAgIBDw8WBh8EBTUvL3d3dy5vcmFuZ2UuZWcvZW4vaGVscC9mYXEtZGV0YWlscz9jYXRlZ29yeT0yMyZRPTIxMx8ABQ5XaGF0IGlzICMxMDAjPx8FBQ5XaGF0IGlzICMxMDAjP2RkAgEPZBYCAgMPZBYEAgEPDxYGHwQFHS8vd3d3Lm9yYW5nZS5lZy9lbi9jb250YWN0LXVzHwAFCkNvbnRhY3QgVXMfBQUKQ29udGFjdCBVc2RkAgMPZBYCAgEPFgIfAwIDFgZmD2QWAgIBDw8WBh8EBR0vL3d3dy5vcmFuZ2UuZWcvZW4vY29udGFjdC11cx8ABQhCeSBwaG9uZR8FBQhCeSBwaG9uZWRkAgEPZBYCAgEPDxYGHwQFHS8vd3d3Lm9yYW5nZS5lZy9lbi9jb250YWN0LXVzHwAFB0J5IGZvcm0fBQUHQnkgZm9ybWRkAgIPZBYCAgEPDxYGHwQFHS8vd3d3Lm9yYW5nZS5lZy9lbi9jb250YWN0LXVzHwAFGFZpYSBzb2NpYWwgbWVkaWEgbmV0d29yax8FBRhWaWEgc29jaWFsIG1lZGlhIG5ldHdvcmtkZAIFDxYCHwFoFgICAw8WAh8DAv////8PZAIED2QWAgIDD2QWAmYPZBYEAgEPFgIfAWhkAgUPFgIeBXZhbHVlBQPvgIJkAgUPFgIeBWNsYXNzBQlBY3RpdmVUYWJkAgYPFgIfCAUMTm9uQWN0aXZlVGFiZAIHDxYCHwYFGC8vc2hvcC5vcmFuZ2UuZWcvZW4vY2FydGQCCQ8WAh8GBSJodHRwczovL2RzbC5vcmFuZ2UuZWdlbi9teWFjY291bnQvZAIWD2QWAgICD2QWBAIBD2QWAgIBDxYCHwMCBBYIZg9kFgICAQ8WAh8IBQ5MZWZ0TmF2Tm9DaGlsZBYIAgEPFgQfBgUTLy9kc2wub3JhbmdlLmVnL2VuLx4FdGl0bGUFCEhvbWVwYWdlFgJmDxUBCEhvbWVwYWdlZAIDDw8WAh8ABQhIb21lcGFnZWRkAgUPFgIfAAUBMWQCBw8WAh8IBQ5FbnRlck90aGVyVGFicxYCAgEPFgIfAwL/////D2QCAQ9kFgICAQ8WAh8IBQ5MZWZ0TmF2Tm9DaGlsZBYIAgEPFgQfBgUyLy9kc2wub3JhbmdlLmVnL2VuL3BhY2thZ2VzL2hvbWUtaW50ZXJuZXQtcGFja2FnZXMfCQUHUGFja2FnZRYCZg8VAQdQYWNrYWdlZAIDDw8WAh8ABQdQYWNrYWdlZGQCBQ8WAh8ABQE3ZAIHDxYCHwgFDkVudGVyT3RoZXJUYWJzFgICAQ8WAh8DAv////8PZAICD2QWAgIBD2QWCAIBDxYGHwgFDkVudGVyT3RoZXJUYWJzHwZkHwkFEE15IEhvbWUgSW50ZXJuZXQWAmYPFQEQTXkgSG9tZSBJbnRlcm5ldGQCAw8PFgQfAAUQTXkgSG9tZSBJbnRlcm5ldB8BZ2RkAgUPFgIfAAUBM2QCBw9kFgICAQ8WAh8DAgcWDmYPZBYEAgEPFgQfBgUUL2VuL3VwZGF0ZWNvbnRhY3RvdHAfCQUVVXBkYXRlIG1vYmlsZSBjb250YWN0FgJmDxUBFVVwZGF0ZSBtb2JpbGUgY29udGFjdGQCAw8PFgIfAAUVVXBkYXRlIG1vYmlsZSBjb250YWN0ZGQCAQ9kFgQCAQ8WBB8GBR0vL2RzbC5vcmFuZ2UuZWcvZW4vbXlhY2NvdW50Lx8JBRFNYW5hZ2UgbXkgYWNjb3VudBYCZg8VARFNYW5hZ2UgbXkgYWNjb3VudGQCAw8PFgIfAAURTWFuYWdlIG15IGFjY291bnRkZAICD2QWBAIBDxYEHwYFJy8vZHNsLm9yYW5nZS5lZy9lbi9teWFjY291bnQvdmlldy1iaWxscx8JBQlWaWV3IGJpbGwWAmYPFQEJVmlldyBiaWxsZAIDDw8WAh8ABQlWaWV3IGJpbGxkZAIDD2QWBAIBDxYEHwYFJS8vZHNsLm9yYW5nZS5lZy9lbi9teWFjY291bnQvcGF5LWJpbGwfCQUIUGF5IGJpbGwWAmYPFQEIUGF5IGJpbGxkAgMPDxYCHwAFCFBheSBiaWxsZGQCBA9kFgQCAQ8WBB8GBSwvL2RzbC5vcmFuZ2UuZWcvZW4vbXlhY2NvdW50L3BheW1lbnQtb3B0aW9ucx8JBQ9QYXltZW50IG9wdGlvbnMWAmYPFQEPUGF5bWVudCBvcHRpb25zZAIDDw8WAh8ABQ9QYXltZW50IG9wdGlvbnNkZAIFD2QWBAIBDxYEHwYFJi8vZHNsLm9yYW5nZS5lZy9lbi9teWFjY291bnQvbXliYWxhbmNlHwkFCk15IGJhbGFuY2UWAmYPFQEKTXkgYmFsYW5jZWQCAw8PFgIfAAUKTXkgYmFsYW5jZWRkAgYPZBYEAgEPFgQfBgUrLy9kc2wub3JhbmdlLmVnL2VuL215YWNjb3VudC9yZWNoYXJnZS1xdW90YR8JBQhSZWNoYXJnZRYCZg8VAQhSZWNoYXJnZWQCAw8PFgIfAAUIUmVjaGFyZ2VkZAIDD2QWAgIBDxYCHwgFDkxlZnROYXZOb0NoaWxkFggCAQ8WBB8GBRwvL2RzbC5vcmFuZ2UuZWcvZW4vc2VydmljZXMvHwkFCFNlcnZpY2VzFgJmDxUBCFNlcnZpY2VzZAIDDw8WAh8ABQhTZXJ2aWNlc2RkAgUPFgIfAAUBNGQCBw8WAh8IBQ5FbnRlck90aGVyVGFicxYCAgEPFgIfAwL/////D2QCAw9kFgJmD2QWAgIDD2QWAgIBDxYCHwMCARYCZg9kFgQCAQ8WBB8GBRovZW4vc2VydmljZXMvb3VyLXJlc2VsbGVycx8JBQ1PdXIgUmVzZWxsZXJzFgJmDxUBDU91ciBSZXNlbGxlcnNkAgMPDxYCHwAFDU91ciBSZXNlbGxlcnNkZAIeD2QWAgIBDxYCHwMCAxYGZg9kFgQCAQ8WBB8GBRwvL3d3dy5vcmFuZ2UuZWcvZW4vYnVzaW5lc3MvHwkFCEJ1c2luZXNzFgJmDxUBCEJ1c2luZXNzZAIDDxYCHwMCBRYKZg9kFgICAQ8WBB8GBSsvL3d3dy5vcmFuZ2UuZWcvZW4vYnVzaW5lc3MvYnVzaW5lc3MtcGxhbnMvHwkFDkJ1c2luZXNzIHBsYW5zFgJmDxUBDkJ1c2luZXNzIHBsYW5zZAIBD2QWAgIBDxYEHwYFLy8vd3d3Lm9yYW5nZS5lZy9lbi9idXNpbmVzcy9idXNpbmVzcy1zb2x1dGlvbnMvHwkFEkJ1c2luZXNzIHNvbHV0aW9ucxYCZg8VARJCdXNpbmVzcyBzb2x1dGlvbnNkAgIPZBYCAgEPFgQfBgUtLy93d3cub3JhbmdlLmVnL2VuL2J1c2luZXNzL3NwZWNpYWwtYnVzaW5lc3MvHwkFFFNQRUNJQUwgZm9yIEJ1c2luZXNzFgJmDxUBFFNQRUNJQUwgZm9yIEJ1c2luZXNzZAIDD2QWAgIBDxYEHwYFLi8vd3d3Lm9yYW5nZS5lZy9lbi9idXNpbmVzcy9wYXltZW50LWZhY2lsaXRpZXMfCQUWU2VydmljZXMgYW5kIHBheW1lbnRzIBYCZg8VARZTZXJ2aWNlcyBhbmQgcGF5bWVudHMgZAIED2QWAgIBDxYEHwYFGy8vc2hvcC5vcmFuZ2UuZWcvZW4vZGV2aWNlcx8JBQdEZXZpY2VzFgJmDxUBB0RldmljZXNkAgEPZBYEAgEPFgQfBgUULy9zaG9wLm9yYW5nZS5lZy9lbi8fCQUEU2hvcBYCZg8VAQRTaG9wZAIDDxYCHwMCBhYMZg9kFgICAQ8WBB8GBSUvL3d3dy5vcmFuZ2UuZWcvZW4vb2ZmZXJzLXByb21vdGlvbnMvHwkFFU9mZmVycyBhbmQgcHJvbW90aW9ucxYCZg8VARVPZmZlcnMgYW5kIHByb21vdGlvbnNkAgEPZBYCAgEPFgQfBgUcLy93d3cub3JhbmdlLmVnL2VuL2ludGVybmV0Lx8JBQhJbnRlcm5ldBYCZg8VAQhJbnRlcm5ldGQCAg9kFgICAQ8WBB8GBRsvL3Nob3Aub3JhbmdlLmVnL2VuL2RldmljZXMfCQUHRGV2aWNlcxYCZg8VAQdEZXZpY2VzZAIDD2QWAgIBDxYEHwYFHC8vd3d3Lm9yYW5nZS5lZy9lbi9zZXJ2aWNlcy8fCQUIU2VydmljZXMWAmYPFQEIU2VydmljZXNkAgQPZBYCAgEPFgQfBgUgLy9zaG9wLm9yYW5nZS5lZy9lbi90YXJpZmYtcGxhbnMfCQUMVGFyaWZmIHBsYW5zFgJmDxUBDFRhcmlmZiBwbGFuc2QCBQ9kFgICAQ8WBB8GBSEvL3d3dy5vcmFuZ2UuZWcvZW4vZW50ZXJ0YWlubWVudC8fCQUNRW50ZXJ0YWlubWVudBYCZg8VAQ1FbnRlcnRhaW5tZW50ZAICD2QWBAIBDxYGHwYFE2phdmFzY3JpcHQ6dm9pZCgwKTsfCQULUXVpY2sgTGlua3MeBXN0eWxlBSVwb2ludGVyLWV2ZW50czogbm9uZTtjdXJzb3I6IGRlZmF1bHQ7FgJmDxUBC1F1aWNrIExpbmtzZAIDDxYCHwMCBBYIZg9kFgICAQ8WBB8GBRkvL3d3dy5vcmFuZ2UuZWcvZW4vYWJvdXQvHwkFEkFib3V0IE9yYW5nZSBFZ3lwdBYCZg8VARJBYm91dCBPcmFuZ2UgRWd5cHRkAgEPZBYCAgEPFgQfBgUdLy93d3cub3JhbmdlLmVnL2VuL215YWNjb3VudC8fCQUKTXkgYWNjb3VudBYCZg8VAQpNeSBhY2NvdW50ZAICD2QWAgIBDxYEHwYFIy8vd3d3Lm9yYW5nZS5lZy9lbi9hYm91dC9pbnZlc3RvcnMvHwkFEkludmVzdG9yIHJlbGF0aW9ucxYCZg8VARJJbnZlc3RvciByZWxhdGlvbnNkAgMPZBYCAgEPFgQfBgUYLy93d3cub3JhbmdlLmVnL2VuL2hlbHAvHwkFBEhlbHAWAmYPFQEESGVscGQCBw9kFgICAw8WAh4TUHJldmlvdXNDb250cm9sTW9kZQspiAFNaWNyb3NvZnQuU2hhcmVQb2ludC5XZWJDb250cm9scy5TUENvbnRyb2xNb2RlLCBNaWNyb3NvZnQuU2hhcmVQb2ludCwgVmVyc2lvbj0xNS4wLjAuMCwgQ3VsdHVyZT1uZXV0cmFsLCBQdWJsaWNLZXlUb2tlbj03MWU5YmNlMTExZTk0MjljAWQYAgUeX19Db250cm9sc1JlcXVpcmVQb3N0QmFja0tleV9fFgIFSGN0bDAwJGN0bDMyJGdfMzc1NWJkYTNfMDU1ZF80MGZkXzk4MzVfMjNlY2M2ZmYyMjA3JGN0bDAwJHJkb1BheUFub255bW91cwVIY3RsMDAkY3RsMzIkZ18zNzU1YmRhM18wNTVkXzQwZmRfOTgzNV8yM2VjYzZmZjIyMDckY3RsMDAkcmRvUGF5QW5vbnltb3VzBUdjdGwwMCRjdGwzMiRnXzM3NTViZGEzXzA1NWRfNDBmZF85ODM1XzIzZWNjNmZmMjIwNyRjdGwwMCRncmRVbnBhaWRCaWxscw9nZGIGenbu4qIfPKRQrPAu7WkzxRjTknW6WzJkPh6OSlhm',
          '__VIEWSTATEGENERATOR': 'BAB98CB3',
          '__EVENTVALIDATION':
              '/wEdAAaxdgWcQvp4Vcn3TyDkxvHra9Eaw86JEidWDUzph4JWaJm4g8IhHlv7AL1c7JOValWiHp4tfVmIu/EWt2mxKUQO7jVPY2jOYKqHqXdiByq+y/ecvcZHqNTI10Ncq59JzZkgKyKBED0x4J4y5jxlYXj7NdbgZXrMXCw7tyVhidE5Kg==',
          'ctl00\$OrangeMenu\$SearchBox\$txtSearch': '',
          'ctl00\$ctl32\$g_3755bda3_055d_40fd_9835_23ecc6ff2207\$ctl00\$pay':
              '1',
          'ctl00\$ctl32\$g_3755bda3_055d_40fd_9835_23ecc6ff2207\$ctl00\$txtLineNumber':
              "$code$phone",
          'ctl00\$ctl32\$g_3755bda3_055d_40fd_9835_23ecc6ff2207\$ctl00\$btnGetUserBills':
              'Get bills',
        }));
  }

  @override
  String toString() {
    return "Orange";
  }
}
