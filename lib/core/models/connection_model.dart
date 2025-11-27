import 'package:flutter/material.dart';

// Model untuk public.profiles
class ProfileModel {
  final String id;
  final String username;
  final String fullName;
  final String? avatarUrl;

  ProfileModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      username: json['username'] ?? 'No Username',
      fullName: json['full_name'] ?? 'No Name',
      avatarUrl: json['avatar_url'],
    );
  }

  // Helper untuk warna avatar (UI Only)
  Color get avatarColor => Colors.blueAccent; // Bisa diganti logika random color
  String get initials => fullName.isNotEmpty 
      ? fullName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase() 
      : '?';
}

// Model untuk public.connections (digabung dengan data profile teman)
class ConnectionModel {
  final String id;
  final String requesterId;
  final String receiverId;
  final String status;
  
  // Data teman (profil orang lain dalam hubungan ini)
  final ProfileModel friendProfile;

  ConnectionModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.friendProfile,
  });

  factory ConnectionModel.fromSupabase(Map<String, dynamic> json, String myUserId) {
    // Tentukan siapa "teman" dalam hubungan ini
    // Jika saya requester, maka teman adalah receiver.
    // Jika saya receiver, maka teman adalah requester.
    final isMeRequester = json['requester_id'] == myUserId;
    
    final friendData = isMeRequester 
        ? json['receiver_profile'] // Data hasil join (alias)
        : json['requester_profile']; // Data hasil join (alias)

    return ConnectionModel(
      id: json['id'],
      requesterId: json['requester_id'],
      receiverId: json['receiver_id'],
      status: json['status'],
      friendProfile: ProfileModel.fromJson(friendData),
    );
  }
}