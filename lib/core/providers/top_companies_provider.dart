// ============================================================
// core/providers/top_companies_provider.dart
// Handles top companies state with Riverpod AsyncNotifier
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api/job_service.dart';

class CompanyModel {
  final String companyName;
  final String? companyLogoUrl;
  final String? companyUrl;
  final String? industry;
  final String? location;
  final int openPositions;
  final String? latestPost;

  CompanyModel({
    required this.companyName,
    this.companyLogoUrl,
    this.companyUrl,
    this.industry,
    this.location,
    required this.openPositions,
    this.latestPost,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      companyName: json['company_name'] as String? ?? 'Unknown',
      companyLogoUrl: json['company_logo_url'] as String?,
      companyUrl: json['company_url'] as String?,
      industry: json['industry'] as String?,
      location: json['location'] as String?,
      openPositions: json['open_positions'] as int? ?? 0,
      latestPost: json['latest_post'] as String?,
    );
  }
}

class TopCompaniesState {
  final List<CompanyModel> companies;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final bool hasReachedMax;

  const TopCompaniesState({
    this.companies = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasReachedMax = false,
  });

  TopCompaniesState copyWith({
    List<CompanyModel>? companies,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    bool? hasReachedMax,
  }) {
    return TopCompaniesState(
      companies: companies ?? this.companies,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

final topCompaniesProvider =
    AsyncNotifierProvider<TopCompaniesNotifier, TopCompaniesState>(() => TopCompaniesNotifier());

class TopCompaniesNotifier extends AsyncNotifier<TopCompaniesState> {
  final JobService _jobService = JobService();

  @override
  Future<TopCompaniesState> build() async {
    await fetchTopCompanies();
    return state.hasValue ? state.value! : const TopCompaniesState();
  }

  Future<void> fetchTopCompanies() async {
    state = AsyncValue.data(const TopCompaniesState(isLoading: true));
    
    try {
      final result = await _jobService.getTopCompanies(
        page: 1,
        limit: 20,
      );

      if (result['success']) {
        final companiesData = result['companies'] as List;
        final companies = companiesData
            .map((company) => CompanyModel.fromJson(company))
            .toList();
        final pagination = result['pagination'] as Map<String, dynamic>;
        
        state = AsyncValue.data(TopCompaniesState(
          companies: companies,
          isLoading: false,
          currentPage: 1,
          totalPages: (pagination['pages'] as num?)?.toInt() ?? 1,
          hasReachedMax: companies.length < 20,
        ));
      } else {
        state = AsyncValue.data(TopCompaniesState(
          errorMessage: result['message'] ?? 'Failed to fetch top companies',
          isLoading: false,
        ));
      }
    } catch (e) {
      state = AsyncValue.data(TopCompaniesState(
        errorMessage: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> loadMore() async {
    final currentState = state.hasValue ? state.value! : const TopCompaniesState();
    
    if (currentState.isLoadingMore || currentState.hasReachedMax) return;

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.currentPage + 1;
      final result = await _jobService.getTopCompanies(
        page: nextPage,
        limit: 20,
      );

      if (result['success']) {
        final companiesData = result['companies'] as List;
        final newCompanies = companiesData
            .map((company) => CompanyModel.fromJson(company))
            .toList();
        
        state = AsyncValue.data(currentState.copyWith(
          companies: [...currentState.companies, ...newCompanies],
          isLoadingMore: false,
          currentPage: nextPage,
          hasReachedMax: newCompanies.length < 20,
        ));
      } else {
        state = AsyncValue.data(currentState.copyWith(
          isLoadingMore: false,
          errorMessage: result['message'] ?? 'Failed to load more companies',
        ));
      }
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> refresh() async {
    await fetchTopCompanies();
  }
}
