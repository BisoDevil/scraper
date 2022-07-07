import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';

import 'package:interpolator/interpolator.dart';
import 'package:intl/intl.dart';
import 'package:pool/pool.dart';
import 'package:scraper/app/data/billing.dart';
import 'package:scraper/app/data/etisalat.dart';
import 'package:scraper/app/data/orange.dart';
import 'package:scraper/app/data/scrapper.dart';
import 'package:scraper/app/data/vodafone.dart';
import 'package:scraper/app/data/we.dart';
import 'package:scraper/app/modules/workflow/workflow_jobinput_reader.dart';
import 'package:scraper/io/logger.dart';
import 'package:scraper/io/writer.dart';
import 'package:scraper/utils/preferences.dart';

class WorkflowExector {
  Map<String, dynamic> workflow;
  AppPreferences prefs;
  void Function(String) writeLog;
  WorkflowExector(
    this.workflow, {
    this.writeLog = print,
  }) {
    globalVars["dir"] = Directory(Platform.resolvedExecutable).parent.path;
  }
  var progress = 0.0.obs;
  var current = "".obs;
  Map<String, dynamic> globalVars = {};
  int maxPooling;
  int batchCapacity;
  int numTrialsOnError;
  int logMaxCharCount;
  int maxWaitAfterErrorMills;
  int minWaitAfterErrorMills;
  var currentJobIndex = 0.obs;
  Completer _oneJobcompleter;
  Future<void> start() async {
    prefs = await AppPreferences.getInstance();
    final jobs = workflow['jobs'] as List<dynamic>;
    globalVars["startJobsTime"] = DateTime.now();
    for (var jobIndex = 0; jobIndex < jobs.length; jobIndex++) {
      progress.value = 0.0;
      currentJobIndex(jobIndex);
      final currentJob = jobs[currentJobIndex.value];
      // make object for all $i (job i) variables
      globalVars["\$$jobIndex"] = {};
      setJobVar("startTime", DateTime.now());
      setJobVar('input', _intp(currentJob['input']));
      setJobVar('output_billing', _intp(currentJob['output_billing']));
      setJobVar('output_general', _intp(currentJob['output_general']));
      setJobVar('output_log', _intp(currentJob['output_log']));
      for (var option in (currentJob['options'] ?? {}).entries) {
        //? may want to interpolate option.value
        setJobVar('options.${option.key}', option.value);
      }
      writeLog("WORKFLOW:: starting job $jobIndex (${currentJob['name']})");
      // for each job:
      // we init the job options
      initJobOptions(currentJob['options']);
      // execute the job
      _oneJobcompleter = Completer();
      await doJob(jobIndex, currentJob);
      writeLog("job $jobIndex ended");
    }
    currentJobIndex.value += 1;
    writeLog(
        "workflow Finished...... (Takes ${DateTime.now().difference(globalVars["startJobsTime"]).toString()})");
  }

  dynamic jobVars(String key, {int jobIndex}) {
    final index = jobIndex ?? currentJobIndex;
    return globalVars['\$$index.$key'];
  }

  void setJobVar(String key, dynamic value, {int jobIndex}) {
    final index = jobIndex ?? currentJobIndex;
    globalVars['\$$index.$key'] = value;
  }

  void unsetRecord(String id) {
    globalVars.removeWhere((key, value) => key.startsWith(id + ".record"));
  }

  void initJobOptions(Map<String, dynamic> options) {
    options = options ?? {};
    // etisalat
    final eusername = options['etisalatUsername'] ?? prefs.etisalatUsername;
    final epass = options['etisalatPassword'] ?? prefs.etisalatPassword;
    if (eusername != null && epass != null) {
      EtisalatScrapper().init(eusername, epass);
    }
    // vodafone
    final vusername = options['vodafoneUsername'] ?? prefs.vodafoneUsername;
    final vpass = options['vodafonePassword'] ?? prefs.vodafonePassword;
    final vsid = options['vodafoneSID'] ?? prefs.vodafoneSID;
    if (vusername != null && vpass != null && vsid != null) {
      VodafoneScrapper().init(vusername, vpass, vsid);
    }
    // billing
    final bgracePeriod = options['gracePeriodDays'] ?? prefs.gracePeriodDays;
    if (bgracePeriod != null) {
      BillingScrapper().init(gracePeriodDays: bgracePeriod);
    }
    // orange
    final orangeConfidence =
        options['orangeConfidence'] ?? prefs.orangeConfidence;
    if (orangeConfidence != null) {
      OrangeScrapper().init(confidenceTrials: orangeConfidence);
    }
    // init option variables
    maxPooling = options['maxPooling'] ?? maxPooling ?? prefs.maxPooling;
    batchCapacity =
        options['batchCapacity'] ?? batchCapacity ?? prefs.batchCapacity;
    numTrialsOnError = options['numTrialsOnError'] ??
        numTrialsOnError ??
        prefs.numTrialsOnError;
    logMaxCharCount =
        options['logMaxCharCount'] ?? logMaxCharCount ?? prefs.logMaxCharCount;
    maxWaitAfterErrorMills = options['maxWaitAfterErrorMills'] ??
        maxWaitAfterErrorMills ??
        prefs.maxWaitAfterErrorMills;
    minWaitAfterErrorMills = options['minWaitAfterErrorMills'] ??
        minWaitAfterErrorMills ??
        prefs.minWaitAfterErrorMills;
  }

  Future<void> doJob(int index, Map<String, dynamic> job) async {
    // read job input
    final input = JobInputReader.read(jobVars('input'), job['inputType']);
    // for each number do
    // filter it and consider fileterStrategy
    // run over providers specified
    try {
      progress.value = 0;
      current.value = "";
      final billingCSVPath = jobVars('output_billing').toString();
      final generalCSVPath = jobVars('output_general').toString();
      final providers = job['providers'];
      RunLogger().directTo(jobVars('output_log'));
      writeLog("Start crawling with pooling $maxPooling......");
      final batchPooler = Pool(maxPooling, timeout: Duration(days: 2));
      var i = 0;
      for (var iline = 0; iline < input.numbers.length; iline++) {
        final id = input.numbers[iline];
        final line = input.params[id]['number'];
        final _data = line.split("-");
        final code = _data.first;
        final phone = _data[1];
        // final id = input.params[line]['id'] ?? (iline + 1).toString();

        /// set record vars
        for (var item in input.params[id].entries) {
          globalVars["$id.record.${item.key}"] = item.value;
        }
        final resource = await batchPooler.request();

        /// apply filter policy
        final variables = job['filters']['variables'] ?? [];
        final isAnd = job['filters']['summation'] == "and";
        var shouldFilter = isAnd; // false || x = x       true && x = x
        for (var variable in variables) {
          shouldFilter = isAnd
              ? shouldFilter && calcFilter(variable, id)
              : shouldFilter || calcFilter(variable, id);
        }
        if (shouldFilter) {
          next(null, input, line, resource, ++i, id, providers, billingCSVPath,
              generalCSVPath,
              shouldLog: false,
              shouldWrite: job['filterStrategy'] == "conserve");
        } else {
          LandlineProvidersManager()
              .validateNumber(
                llid: id,
                code: code.startsWith("0") ? code : "0$code",
                phone: phone,
                allowEtisalat: providers.contains("etisalat"),
                allowVodafone: providers.contains("vodafone"),
                allowOrange: providers.contains("orange"),
                allowWe: providers.contains("we"),
                allowBilling: providers.contains("billing"),
                trials: numTrialsOnError,
                waitAfterErrorMaxMillis: maxWaitAfterErrorMills,
                waitAfterErrorMinMillis: minWaitAfterErrorMills,
                writeLog: writeLog,
              )
              .then((r) => next(r, input, line, resource, ++i, id, providers,
                  billingCSVPath, generalCSVPath))
              .catchError((e) {
            print(
                "Error in handling validate number response: ${e.toString()}");
            writeLog(
                "error in handling validate number response. ${e.toString()}");
            _oneJobcompleter.completeError(e);
          });
        }
      }
    } catch (e) {
      print("Error in starting crawling: ${e.toString()}");
      writeLog("error in starting crawling. ${e.toString()}");
      _oneJobcompleter.completeError(e);
    }

    return _oneJobcompleter.future;
  }

  next(LandlineProvidersResponse response, input, line, resource, i, id,
      providers, billingCSVPath, generalCSVPath,
      {shouldWrite = true, shouldLog = true}) {
    print("AMMAR:: resource hash code ${resource.hashCode}");
    resource.release();
    unsetRecord(id); // release memory
    progress(i / input.numbers.length);
    current("$i/${input.numbers.length}");
    response = rebuildLandlineResponse(response, input, id);
    if (shouldLog) {
      writeLog(
          "[!] 0$line is ${response.status.name} (${response.generalResponse})");
    }
    if (shouldWrite &&
        billingCSVPath != null &&
        providers.contains("billing")) {
      Writer().writeBillingExcelSheet(
        [response.billingResponse],
        path: billingCSVPath,
        shouldContinue: true,
      );
    }
    if (shouldWrite &&
        generalCSVPath != null) {
      // write responses of providers
      Writer().writeGeneralExcelSheet([response],
          path: generalCSVPath, shouldContinue: true);
    }
    if (i >= input.numbers.length) {
      final endTime = DateTime.now();
      setJobVar("endTime", endTime);
      writeLog(
          "Finished...... (Takes ${endTime.difference(jobVars('startTime')).toString()})");
      _oneJobcompleter.complete();
    }
  }

  bool calcFilter(filter, id) {
    final op1 = _intp(filter['operand1'], landlineId: id);
    final op2 = _intp(filter['operand2'], landlineId: id);
    final operator = filter['operator'];
    final name = filter['name'];
    var res = false;
    if (operator == "==") {
      res = op1 == op2;
    }
    if (operator == "!=") {
      res = op1 != op2;
    }
    // TODO: add more operators and split in different class
    setJobVar(name, res);
    return res;
  }

  LandlineProvidersResponse rebuildLandlineResponse(
    LandlineProvidersResponse base,
    WorkflowInput input,
    id,
  ) {
    final lparams = input.params[id];
    base ??= LandlineProvidersResponse(
        LandlineProvidersStatus.values.firstWhere((element) =>
            element.name == lparams['status'] ?? lparams['billing']),
        generalResponse: "NONE");
    final billingStatus =
        lparams['billing'] != null && lparams['billing'] != "null"
            ? BillingStatus(lparams['billing'])
            : null;
    final etisalatStatus =
        lparams['etisalat'] != null && lparams['etisalat'] != "null"
            ? EtisalatStatus(lparams['etisalat'])
            : null;
    final weStatus = lparams['we'] != null && lparams['we'] != "null"
        ? WeStatus(lparams['we'])
        : null;
    final orangeStatus =
        lparams['orange'] != null && lparams['orange'] != "null"
            ? OrangeStatus(lparams['orange'])
            : null;
    final vodafoneStatus =
        lparams['vodafone'] != null && lparams['vodafone'] != "null"
            ? VodafoneStatus(lparams['vodafone'])
            : null;
    base.billingResponse ??= billingStatus != null
        ? BillingResponse(
            status: billingStatus,
            id: lparams['id'],
            countryCode: lparams['code'],
            landline: lparams['landline'],
            comment: _extractProviderComment(lparams['comment'], 'Billing'),
            customerCategory: lparams['customerCategory'] ?? "",
            deposit: double.tryParse(lparams['DEPOSIT'] ?? ""),
            errorMessage: lparams['errorMessage'] ?? "",
            lastBillAmount: double.tryParse(lparams['lastBillAmount'] ?? ""),
            newLandlineNumber: lparams['LL'] ?? "",
          )
        : null;

    base.etisalatResponse ??= etisalatStatus != null
        ? EtisalatResponse(
            id: lparams['id'],
            countryCode: lparams['code'],
            landline: lparams['landline'],
            comment: _extractProviderComment(lparams['comment'], 'Etisalat'),
            status: etisalatStatus,
            errorMessage: lparams['etisalat_error'],
          )
        : null;
    base.weResponse ??= weStatus != null
        ? WeResponse(
            id: lparams['id'],
            countryCode: lparams['code'],
            landline: lparams['landline'],
            comment: _extractProviderComment(lparams['comment'], 'We'),
            status: weStatus,
            errorMessage: lparams['we_error'],
          )
        : null;
    base.orangeResponse ??= orangeStatus != null
        ? OrangeResponse(
            id: lparams['id'],
            countryCode: lparams['code'],
            landline: lparams['landline'],
            comment: _extractProviderComment(lparams['comment'], 'Orange'),
            status: orangeStatus,
            errorMessage: lparams['orange_error'],
          )
        : null;
    base.vodafoneResponse ??= vodafoneStatus != null
        ? VodafoneResponse(
            id: lparams['id'],
            countryCode: lparams['code'],
            landline: lparams['landline'],
            comment: _extractProviderComment(lparams['comment'], 'Vodafone'),
            status: vodafoneStatus,
            errorMessage: lparams['vodafone_error'],
          )
        : null;
    return base;
  }

  String _intp(String input, {String landlineId = ''}) {
    final element = Interpolator(input);
    Map<String, dynamic> map = {};
    for (var interploationKey in element.keys) {
      interploationKey = interploationKey.toString();

      /// key in the globalVariables
      final interploationKeyUpdated =
          interploationKey.replaceAll("record.", "$landlineId.record.");
      if (globalVars[interploationKeyUpdated] != null) {
        dynamic value = globalVars[interploationKeyUpdated];
        if (value is DateTime) {
          value = DateFormat("y-M-d H-m").format(value);
        }
        map[interploationKey] = value;
      } else {
        throw ("Can't find variable $interploationKeyUpdated");
      }
    }
    return element(map);
  }

  String _extractProviderComment(String comment, String name) {
    if (comment == null) return "";
    final _data = comment.split("<$name>");
    if (_data.length <= 1) return "";
    return _data[1].split("</$name>")[0];
  }
}
