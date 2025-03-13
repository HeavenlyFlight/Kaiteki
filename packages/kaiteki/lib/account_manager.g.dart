// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$accountSecretRepositoryHash() =>
    r'28651e12ba77ef738df54061d25b767585847e1d';

/// See also [accountSecretRepository].
@ProviderFor(accountSecretRepository)
final accountSecretRepositoryProvider =
    AutoDisposeProvider<Repository<AccountSecret, AccountKey>>.internal(
  accountSecretRepository,
  name: r'accountSecretRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$accountSecretRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AccountSecretRepositoryRef
    = AutoDisposeProviderRef<Repository<AccountSecret, AccountKey>>;
String _$clientSecretRepositoryHash() =>
    r'aed3e9014f61ee4cbc6de2836eb5f3e92d8dc635';

/// See also [clientSecretRepository].
@ProviderFor(clientSecretRepository)
final clientSecretRepositoryProvider =
    AutoDisposeProvider<Repository<ClientSecret, AccountKey>>.internal(
  clientSecretRepository,
  name: r'clientSecretRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$clientSecretRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ClientSecretRepositoryRef
    = AutoDisposeProviderRef<Repository<ClientSecret, AccountKey>>;
String _$accountManagerHash() => r'8b6086bd3a53dde0f8f5d960fb81cc723c7a79a4';

/// See also [AccountManager].
@ProviderFor(AccountManager)
final accountManagerProvider =
    NotifierProvider<AccountManager, AccountManagerState>.internal(
  AccountManager.new,
  name: r'accountManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$accountManagerHash,
  dependencies: <ProviderOrFamily>[
    accountSecretRepositoryProvider,
    clientSecretRepositoryProvider
  ],
  allTransitiveDependencies: <ProviderOrFamily>{
    accountSecretRepositoryProvider,
    ...?accountSecretRepositoryProvider.allTransitiveDependencies,
    clientSecretRepositoryProvider,
    ...?clientSecretRepositoryProvider.allTransitiveDependencies
  },
);

typedef _$AccountManager = Notifier<AccountManagerState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
