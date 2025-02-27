// To parse this JSON data, do
//
//     final friendModel = friendModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../profile/own_profile_basic.dart';

FriendModel friendModelFromJson(String str) => FriendModel.fromJson(json.decode(str));

String friendModelToJson(FriendModel data) => json.encode(data.toJson());

class FriendModel {
  // For state management
  bool isUpdating = false;
  bool justUpdatedWithError = false;
  bool justUpdatedWithSuccess = false;

  // External, exported/imported to Shared Preferences!
  String personalNote;
  String personalNoteColor;
  DateTime lastUpdated;
  bool hasFaction;

  FriendModel({
    // This first batch is here to export/import from SharedPreferences,
    // so we also have to initialize them below
    this.personalNote,
    this.personalNoteColor,
    this.lastUpdated,
    this.hasFaction,
    /////////////////

    this.rank,
    this.level,
    this.gender,
    this.property,
    this.signup,
    this.awards,
    this.friends,
    this.enemies,
    this.forumPosts,
    this.karma,
    this.age,
    this.role,
    this.donator,
    this.playerId,
    this.name,
    this.propertyId,
    this.life,
    this.status,
    this.job,
    this.faction,
    this.married,
    this.states,
    this.lastAction,
    this.discord,
    this.competition,
  });

  String rank;
  int level;
  String gender;
  String property;
  DateTime signup;
  int awards;
  int friends;
  int enemies;
  int forumPosts;
  int karma;
  int age;
  String role;
  int donator;
  int playerId;
  String name;
  int propertyId;
  Life life;
  Status status;
  Job job;
  Faction faction;
  Married married;
  States states;
  LastAction lastAction;
  Discord discord;
  Competition competition;

  factory FriendModel.fromJson(Map<String, dynamic> json) => FriendModel(
        personalNote: json["personalNote"] == null ? '' : json["personalNote"],
        personalNoteColor: json["personalNoteColor"] == null ? '' : json["personalNoteColor"],
        lastUpdated: json["lastUpdated"] == null ? DateTime.now() : DateTime.parse(json["lastUpdated"]),
        hasFaction: json["hasFaction"] == null ? false : json["hasFaction"],
        rank: json["rank"] == null ? null : json["rank"],
        level: json["level"] == null ? null : json["level"],
        gender: json["gender"] == null ? null : json["gender"],
        property: json["property"] == null ? null : json["property"],
        signup: json["signup"] == null ? null : DateTime.parse(json["signup"]),
        awards: json["awards"] == null ? null : json["awards"],
        friends: json["friends"] == null ? null : json["friends"],
        enemies: json["enemies"] == null ? null : json["enemies"],
        forumPosts: json["forum_posts"] == null ? null : json["forum_posts"],
        karma: json["karma"] == null ? null : json["karma"],
        age: json["age"] == null ? null : json["age"],
        role: json["role"] == null ? null : json["role"],
        donator: json["donator"] == null ? null : json["donator"],
        playerId: json["player_id"] == null ? null : json["player_id"],
        name: json["name"] == null ? null : json["name"],
        propertyId: json["property_id"] == null ? null : json["property_id"],
        life: json["life"] == null ? null : Life.fromJson(json["life"]),
        status: json["status"] == null ? null : Status.fromJson(json["status"]),
        job: json["job"] == null ? null : Job.fromJson(json["job"]),
        faction: json["faction"] == null ? null : Faction.fromJson(json["faction"]),
        married: json["married"] == null ? null : Married.fromJson(json["married"]),
        states: json["states"] == null ? null : States.fromJson(json["states"]),
        lastAction: json["last_action"] == null ? null : LastAction.fromJson(json["last_action"]),
        discord: json["discord"] == null ? null : Discord.fromJson(json["discord"]),
        competition: json["competition"] == null ? null : Competition.fromJson(json["competition"]),
      );

  Map<String, dynamic> toJson() => {
        "personalNote": personalNote,
        "personalNoteColor": personalNoteColor,
        "lastUpdated": lastUpdated.toIso8601String(),
        "hasFaction": hasFaction,
        "rank": rank == null ? null : rank,
        "level": level == null ? null : level,
        "gender": gender == null ? null : gender,
        "property": property == null ? null : property,
        "signup": signup == null ? null : signup.toIso8601String(),
        "awards": awards == null ? null : awards,
        "friends": friends == null ? null : friends,
        "enemies": enemies == null ? null : enemies,
        "forum_posts": forumPosts == null ? null : forumPosts,
        "karma": karma == null ? null : karma,
        "age": age == null ? null : age,
        "role": role == null ? null : role,
        "donator": donator == null ? null : donator,
        "player_id": playerId == null ? null : playerId,
        "name": name == null ? null : name,
        "property_id": propertyId == null ? null : propertyId,
        "life": life == null ? null : life.toJson(),
        "status": status == null ? null : status.toJson(),
        "job": job == null ? null : job.toJson(),
        "faction": faction == null ? null : faction.toJson(),
        "married": married == null ? null : married.toJson(),
        "states": states == null ? null : states.toJson(),
        "last_action": lastAction == null ? null : lastAction.toJson(),
        "discord": discord == null ? null : discord.toJson(),
        "competition": competition == null ? null : competition.toJson(),
      };
}

class Discord {
  Discord({
    this.userId,
    this.discordId,
  });

  int userId;
  String discordId;

  factory Discord.fromJson(Map<String, dynamic> json) => Discord(
        userId: json["userID"] == null ? null : json["userID"],
        discordId: json["discordID"] == null ? null : json["discordID"],
      );

  Map<String, dynamic> toJson() => {
        "userID": userId == null ? null : userId,
        "discordID": discordId == null ? null : discordId,
      };
}

class Faction {
  Faction({
    this.position,
    this.factionId,
    this.daysInFaction,
    this.factionName,
  });

  String position;
  int factionId;
  int daysInFaction;
  String factionName;

  factory Faction.fromJson(Map<String, dynamic> json) => Faction(
        position: json["position"] == null ? null : json["position"],
        factionId: json["faction_id"] == null ? null : json["faction_id"],
        daysInFaction: json["days_in_faction"] == null ? null : json["days_in_faction"],
        factionName: json["faction_name"] == null ? null : json["faction_name"],
      );

  Map<String, dynamic> toJson() => {
        "position": position == null ? null : position,
        "faction_id": factionId == null ? null : factionId,
        "days_in_faction": daysInFaction == null ? null : daysInFaction,
        "faction_name": factionName == null ? null : factionName,
      };
}

class Job {
  Job({
    this.job,
    this.position,
    this.companyId,
    this.companyName,
    this.companyType,
  });

  String job;
  String position;
  int companyId;
  String companyName;
  int companyType;

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        job: json["job"] == null ? null : json["job"],
        position: json["position"] == null ? null : json["position"],
        companyId: json["company_id"] == null ? null : json["company_id"],
        companyName: json["company_name"] == null ? null : json["company_name"].toString(),
        companyType: json["company_type"] == null ? null : json["company_type"],
      );

  Map<String, dynamic> toJson() => {
        "job": job == null ? null : job,
        "position": position == null ? null : position,
        "company_id": companyId == null ? null : companyId,
        "company_name": companyName == null ? null : companyName,
        "company_type": companyType == null ? null : companyType,
      };
}

class LastAction {
  LastAction({
    this.status,
    this.timestamp,
    this.relative,
  });

  String status;
  int timestamp;
  String relative;

  factory LastAction.fromJson(Map<String, dynamic> json) => LastAction(
        status: json["status"] == null ? null : json["status"],
        timestamp: json["timestamp"] == null ? null : json["timestamp"],
        relative: json["relative"] == null ? null : json["relative"],
      );

  Map<String, dynamic> toJson() => {
        "status": status == null ? null : status,
        "timestamp": timestamp == null ? null : timestamp,
        "relative": relative == null ? null : relative,
      };
}

class Life {
  Life({
    this.current,
    this.maximum,
    this.increment,
    this.interval,
    this.ticktime,
    this.fulltime,
  });

  int current;
  int maximum;
  int increment;
  int interval;
  int ticktime;
  int fulltime;

  factory Life.fromJson(Map<String, dynamic> json) => Life(
        current: json["current"] == null ? null : json["current"],
        maximum: json["maximum"] == null ? null : json["maximum"],
        increment: json["increment"] == null ? null : json["increment"],
        interval: json["interval"] == null ? null : json["interval"],
        ticktime: json["ticktime"] == null ? null : json["ticktime"],
        fulltime: json["fulltime"] == null ? null : json["fulltime"],
      );

  Map<String, dynamic> toJson() => {
        "current": current == null ? null : current,
        "maximum": maximum == null ? null : maximum,
        "increment": increment == null ? null : increment,
        "interval": interval == null ? null : interval,
        "ticktime": ticktime == null ? null : ticktime,
        "fulltime": fulltime == null ? null : fulltime,
      };
}

class Married {
  Married({
    this.spouseId,
    this.spouseName,
    this.duration,
  });

  int spouseId;
  String spouseName;
  int duration;

  factory Married.fromJson(Map<String, dynamic> json) => Married(
        spouseId: json["spouse_id"] == null ? null : json["spouse_id"],
        spouseName: json["spouse_name"] == null ? null : json["spouse_name"],
        duration: json["duration"] == null ? null : json["duration"],
      );

  Map<String, dynamic> toJson() => {
        "spouse_id": spouseId == null ? null : spouseId,
        "spouse_name": spouseName == null ? null : spouseName,
        "duration": duration == null ? null : duration,
      };
}

class States {
  States({
    this.hospitalTimestamp,
    this.jailTimestamp,
  });

  int hospitalTimestamp;
  int jailTimestamp;

  factory States.fromJson(Map<String, dynamic> json) => States(
        hospitalTimestamp: json["hospital_timestamp"] == null ? null : json["hospital_timestamp"],
        jailTimestamp: json["jail_timestamp"] == null ? null : json["jail_timestamp"],
      );

  Map<String, dynamic> toJson() => {
        "hospital_timestamp": hospitalTimestamp == null ? null : hospitalTimestamp,
        "jail_timestamp": jailTimestamp == null ? null : jailTimestamp,
      };
}

class Competition {
  int attacks;
  String image;
  String name;
  double score;
  int team;
  String text;
  int total;
  int treatsCollectedTotal;
  int votes;
  dynamic position;

  Competition({
    this.attacks,
    this.image,
    this.name,
    this.score,
    this.team,
    this.text,
    this.total,
    this.treatsCollectedTotal,
    this.votes,
    this.position,
  });

  factory Competition.fromJson(Map<String, dynamic> json) {
    try {
      return Competition(
        attacks: json["attacks"] == null ? null : json["attacks"],
        image: json["image"] == null ? null : json["image"],
        name: json["name"] == null ? null : json["name"],
        score: json["score"] == null ? null : json["score"].toDouble(),
        team: json["team"] == null ? null : json["team"],
        text: json["text"] == null ? null : json["text"],
        total: json["total"] == null ? null : json["total"],
        treatsCollectedTotal: json["treats_collected_total"] == null ? null : json["treats_collected_total"],
        votes: json["votes"] == null ? null : json["votes"],
        position: json["position"] == null ? null : json["position"].toString(),
      );
    } catch (e, trace) {
      FirebaseCrashlytics.instance.log("PDA Crash at Competition model");
      FirebaseCrashlytics.instance.recordError("PDA Error: $e", trace);
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        "attacks": attacks == null ? null : attacks,
        "image": image == null ? null : image,
        "name": name == null ? null : name,
        "score": score == null ? null : score,
        "team": team == null ? null : team,
        "text": text == null ? null : text,
        "total": total == null ? null : total,
        "treats_collected_total": treatsCollectedTotal == null ? null : treatsCollectedTotal,
        "votes": votes == null ? null : votes,
        "position": position == null ? null : position,
      };
}
