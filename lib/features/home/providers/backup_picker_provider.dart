import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackupPickerState {
  final String? localPath;
  final bool isPicking;

  BackupPickerState({this.localPath, this.isPicking = false});

  BackupPickerState copyWith({String? localPath, bool? isPicking}) {
    return BackupPickerState(
      localPath: localPath ?? this.localPath,
      isPicking: isPicking ?? this.isPicking,
    );
  }
}

final backupPickerProvider = StateProvider<BackupPickerState?>((ref) => null);
