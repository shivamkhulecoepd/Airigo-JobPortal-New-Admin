import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:airigo_jobportal/core/network/dio_client.dart';
import 'package:airigo_jobportal/models/job_model.dart';
import 'package:dio/dio.dart';

class JobService {
  // Get application stats for the current user
  Future<Map<String, dynamic>> getApplicationStats() async {
    try {
      print('JobService: Fetching application statistics');
      final response = await _dioClient.get('/api/applications/stats');
      final responseData = response.data;
      print('JobService: Application stats response: $responseData');

      if (responseData.containsKey('stats')) {
        return {
          'success': true,
          'stats': responseData['stats'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch stats',
        };
      }
    } on DioException catch (e) {
      print('JobService: Failed to fetch stats with DioException: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('JobService: Failed to fetch stats with general exception: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  final DioClient _dioClient = DioClient();

  // Get all jobs with filters
  Future<Map<String, dynamic>> getAllJobs({
    int page = 1,
    int limit = 10,
    String? location,
    String? category,
    String? jobType,
    int? minCtc,
    int? maxCtc,
    bool? isUrgent,
  }) async {
    try {
      print(
        'JobService: Fetching all jobs with filters - page: $page, limit: $limit, location: $location, category: $category, jobType: $jobType, minCtc: $minCtc, maxCtc: $maxCtc, isUrgent: $isUrgent',
      );

      final params = <String, dynamic>{};
      params['page'] = page;
      params['limit'] = limit;
      if (location != null) params['location'] = location;
      if (category != null) params['category'] = category;
      if (jobType != null) params['job_type'] = jobType;
      if (minCtc != null) params['min_ctc'] = minCtc;
      if (maxCtc != null) params['max_ctc'] = maxCtc;
      if (isUrgent != null) params['is_urgent'] = isUrgent;

      final response = await _dioClient.get('/api/jobs', params: params);
      final responseData = response.data;
      print('JobService: Jobs response received: $responseData');

      if (responseData.containsKey('jobs')) {
        final jobsData = responseData['jobs'] as List;
        print('JobService: Raw jobs data count: ${jobsData.length}');

        // Parse each job individually to catch errors
        final jobs = <JobModel>[];
        for (var jobData in jobsData) {
          try {
            print(
              'JobService: Parsing job - ID: ${jobData['id']}, Designation: ${jobData['designation']}',
            );
            final job = JobModel.fromJson(jobData);
            jobs.add(job);
            print('JobService: Successfully parsed job ID: ${job.id}');
          } catch (e, stackTrace) {
            print('JobService: Error parsing job ${jobData['id']}: $e');
            print('JobService: Stack trace: $stackTrace');
            print('JobService: Job data: $jobData');
          }
        }

        print('JobService: Successfully parsed ${jobs.length} jobs');
        return {
          'success': true,
          'jobs': jobs,
          'pagination': responseData['pagination'],
        };
      } else {
        print('JobService: Failed to fetch jobs: ${responseData['message']}');
        return {
          'success': false,
          'jobs': [],
          'message': responseData['message'] ?? 'Failed to fetch jobs',
        };
      }
    } on DioException catch (e) {
      print('JobService: Failed to fetch jobs with DioException: ${e.message}');
      if (e.response != null) {
        print('JobService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'jobs': [],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('JobService: Failed to fetch jobs with general exception: $e');
      return {
        'success': false,
        'jobs': [],
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get all jobs (simple version)
  Future<Map<String, dynamic>> getAllJobsSimple() async {
    try {
      final response = await _dioClient.get('/api/jobs');
      final responseData = response.data;

      if (responseData.containsKey('jobs')) {
        final jobsData = responseData['jobs'] as List;
        final jobs = jobsData.map((job) => JobModel.fromJson(job)).toList();
        return {'success': true, 'jobs': jobs};
      } else {
        return {
          'success': false,
          'jobs': [],
          'message': responseData['message'] ?? 'Failed to fetch jobs',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'jobs': [],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'jobs': [],
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Search jobs
  Future<Map<String, dynamic>> searchJobs({
    String? query,
    String? location,
    String? category,
    String? designation,
    String? companyName,
    String? jobType,
    int? minCtc,
    int? maxCtc,
    String? experienceRequired,
    bool? isUrgent,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      print(
        'JobService: Searching jobs with params - query: $query, location: $location, category: $category, designation: $designation, company: $companyName, jobType: $jobType, minCtc: $minCtc, maxCtc: $maxCtc, exp: $experienceRequired, urgent: $isUrgent, page: $page, limit: $limit',
      );

      final params = <String, dynamic>{};
      // Don't send empty query - backend only uses filter params
      if (query != null && query.isNotEmpty) params['query'] = query;
      if (location != null) params['location'] = location;
      if (category != null) params['category'] = category;
      if (designation != null) params['designation'] = designation;
      if (companyName != null) params['company_name'] = companyName;
      if (jobType != null) params['job_type'] = jobType;
      if (minCtc != null) params['min_ctc'] = minCtc;
      if (maxCtc != null) params['max_ctc'] = maxCtc;
      if (experienceRequired != null) {
        params['experience_required'] = experienceRequired;
      }
      if (isUrgent != null) params['is_urgent'] = isUrgent;
      params['page'] = page;
      params['limit'] = limit;
      
      print('JobService: Final params: $params');

      final response = await _dioClient.get('/api/jobs/search', params: params);
      final responseData = response.data;
      print('JobService: Search response: $responseData');

      if (responseData.containsKey('jobs')) {
        final jobsData = responseData['jobs'] as List;
        final jobs = jobsData.map((job) => JobModel.fromJson(job)).toList();
        print('JobService: Found ${jobs.length} jobs matching search criteria');
        return {
          'success': true,
          'jobs': jobs,
          'pagination': responseData['pagination'],
        };
      } else {
        print('JobService: Search failed: ${responseData['message']}');
        return {
          'success': false,
          'jobs': [],
          'message': responseData['message'] ?? 'Failed to search jobs',
        };
      }
    } on DioException catch (e) {
      print('JobService: Search failed with DioException: ${e.message}');
      if (e.response != null) {
        print('JobService: Response data: ${e.response!.data}');
        print('JobService: Response status code: ${e.response!.statusCode}');
      }
      return {
        'success': false,
        'jobs': [],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('JobService: Search failed with general exception: $e');
      return {
        'success': false,
        'jobs': [],
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Create job posting
  Future<Map<String, dynamic>> createJob({
    required String companyName,
    String? companyLogoUrl,
    String? companyLogoPath, // Local file path for image upload
    String? companyUrl, // New field
    required String designation,
    required String ctc,
    required String location,
    required String category,
    String? description,
    List<String>? requirements,
    List<String>? skillsRequired,
    List<String>? perksAndBenefits,
    String? experienceRequired, // Changed from int to String
    bool isActive = true,
    bool isUrgentHiring = false,
    String jobType = 'Full-time',
  }) async {
    try {
      print('JobService: Creating job posting - $companyName - $designation');

      final data = <String, dynamic>{
        'company_name': companyName,
        'company_url': companyUrl,
        'designation': designation,
        'ctc': ctc,
        'location': location,
        'category': category,
        'is_active': isActive,
        'is_urgent_hiring': isUrgentHiring,
        'job_type': jobType,
      };

      if (companyLogoUrl != null) data['company_logo_url'] = companyLogoUrl;
      if (description != null) data['description'] = description;
      if (requirements != null) data['requirements'] = requirements;
      if (skillsRequired != null) data['skills_required'] = skillsRequired;
      if (perksAndBenefits != null) data['perks_and_benefits'] = perksAndBenefits;
      if (experienceRequired != null) {
        data['experience_required'] = experienceRequired; // Now accepts string
      }

      // If logo file path is provided, use FormData for multipart upload
      if (companyLogoPath != null && companyLogoPath.isNotEmpty) {
        print('JobService: Uploading logo file along with job creation');
        
        // For FormData, we need to convert non-string values to strings
        final formData = FormData.fromMap({
          'company_name': companyName,
          'company_url': companyUrl ?? '',
          'designation': designation,
          'ctc': ctc,
          'location': location,
          'category': category,
          'description': description ?? '',
          'is_active': isActive ? '1' : '0',
          'is_urgent_hiring': isUrgentHiring ? '1' : '0',
          'job_type': jobType,
          if (experienceRequired != null) 'experience_required': experienceRequired,
          if (requirements != null) 'requirements': jsonEncode(requirements),
          if (skillsRequired != null) 'skills_required': jsonEncode(skillsRequired),
          if (perksAndBenefits != null) 'perks_and_benefits': jsonEncode(perksAndBenefits),
          'logo': await MultipartFile.fromFile(companyLogoPath),
        });

        final response = await _dioClient.post('/api/jobs', data: formData);
        final responseData = response.data;
        log('JobService: Create job with logo response: $responseData');

        if (responseData['success'] == true ||
            (responseData['message'] != null &&
                responseData['message'].toString().contains('success'))) {
          final job = JobModel.fromJson(
            responseData['job'] ?? responseData['data']?['job'] ?? responseData,
          );
          print('JobService: Successfully created job ID: ${job.id}');
          return {
            'success': true,
            'message': responseData['message'] ?? 'Job created successfully',
            'job': job,
          };
        } else {
          print('JobService: Failed to create job: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to create job posting',
          };
        }
      } else {
        // No logo file, send as JSON
        final String prettyJson = const JsonEncoder.withIndent('    ').convert(data);
        log('JobService: Create job data:\n$prettyJson');

        final response = await _dioClient.post('/api/jobs', data: data);
        final responseData = response.data;
        log('JobService: Create job response: $responseData');

        if (responseData['success'] == true ||
            (responseData['message'] != null &&
                responseData['message'].toString().contains('success'))) {
          final job = JobModel.fromJson(
            responseData['job'] ?? responseData['data']?['job'] ?? responseData,
          );
          print('JobService: Successfully created job ID: ${job.id}');
          return {
            'success': true,
            'message': responseData['message'] ?? 'Job created successfully',
            'job': job,
          };
        } else {
          print('JobService: Failed to create job: ${responseData['message']}');
          print('JobService: Full response: $responseData');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to create job posting',
          };
        }
      }
    } on DioException catch (e) {
      print('JobService: Create job failed with DioException: ${e.message}');
      print('JobService: DioException type: ${e.type}');
      if (e.response != null) {
        print('JobService: Response status code: ${e.response!.statusCode}');
        print('JobService: Response data: ${e.response!.data}');
        print('JobService: Response headers: ${e.response!.headers}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e, stackTrace) {
      print('JobService: Create job failed with general exception: $e');
      print('JobService: Stack trace: $stackTrace');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // Update job posting
  Future<Map<String, dynamic>> updateJob({
    required int jobId,
    String? companyName,
    String? companyLogoUrl,
    String? companyLogoPath, // Local file path for image upload
    String? companyUrl, // New field
    String? designation,
    String? ctc,
    String? location,
    String? category,
    String? description,
    List<String>? requirements,
    List<String>? skillsRequired,
    List<String>? perksAndBenefits,
    String? experienceRequired, // Changed from int to String
    bool? isActive,
    bool? isUrgentHiring,
    String? jobType,
  }) async {
    try {
      print('JobService: Updating job ID: $jobId');

      final data = <String, dynamic>{};
      if (companyName != null) data['company_name'] = companyName;
      if (companyUrl != null) {
        data['company_url'] = companyUrl; // Include the new field
      }
      if (designation != null) data['designation'] = designation;
      if (ctc != null) data['ctc'] = ctc;
      if (location != null) data['location'] = location;
      if (category != null) data['category'] = category;
      if (companyLogoUrl != null) data['company_logo_url'] = companyLogoUrl;
      if (description != null) data['description'] = description;
      if (requirements != null) data['requirements'] = requirements;
      if (skillsRequired != null) data['skills_required'] = skillsRequired;
      if (perksAndBenefits != null) data['perks_and_benefits'] = perksAndBenefits;
      if (experienceRequired != null) {
        data['experience_required'] =
            experienceRequired; // Now accepts string
      }
      if (isActive != null) data['is_active'] = isActive;
      if (isUrgentHiring != null) data['is_urgent_hiring'] = isUrgentHiring;
      if (jobType != null) data['job_type'] = jobType;

      // Handle logo upload for updates - send as base64 to avoid FormData issues with PUT
      if (companyLogoPath != null && companyLogoPath.isNotEmpty) {
        print('JobService: Encoding logo for job update');
        print('JobService: Logo file path: $companyLogoPath');

        // Read file and encode as base64
        final file = File(companyLogoPath);
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);

        // Get file extension for MIME type detection
        final extension = companyLogoPath.split('.').last.toLowerCase();
        String mimeType;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
          default:
            mimeType = 'image/jpeg'; // Default fallback
        }

        data['company_logo_base64'] = base64Image;
        data['company_logo_mime_type'] = mimeType;
        data['company_logo_filename'] = 'logo.$extension';

        print('JobService: Logo encoded as base64, length: ${base64Image.length}');
      }

      if (data.isEmpty) {
        return {'success': false, 'message': 'No fields to update'};
      }

      final String prettyJson = const JsonEncoder.withIndent('    ').convert(data);
      log('JobService: Update job data:\n$prettyJson');

      final response = await _dioClient.put('/api/jobs/$jobId', data: data);
      final responseData = response.data;
      log('JobService: Update job response: $responseData');

      if (responseData['success'] == true ||
          (responseData['message'] != null &&
              responseData['message'].toString().contains('success'))) {
        final job = JobModel.fromJson(
          responseData['job'] ?? responseData['data']?['job'] ?? responseData,
        );
        print('JobService: Successfully updated job ID: ${job.id}');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Job updated successfully',
          'job': job,
        };
      } else {
        print('JobService: Failed to update job: ${responseData['message']}');
        print('JobService: Full response: $responseData');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update job posting',
        };
      }
    } on DioException catch (e) {
      print('JobService: Update job failed with DioException: ${e.message}');
      if (e.response != null) {
        print('JobService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('JobService: Update job failed with general exception: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // Get job by ID
  Future<Map<String, dynamic>> getJobById(String jobId) async {
    try {
      print('JobService: Fetching job by ID: $jobId');
      final response = await _dioClient.get('/api/jobs/$jobId');
      final responseData = response.data;
      print('JobService: Job details response: $responseData');

      if (responseData.containsKey('job')) {
        final jobData = responseData['job'];
        final job = JobModel.fromJson(jobData);
        print('JobService: Successfully fetched job: ${job.designation}');
        return {'success': true, 'job': job};
      } else {
        print('JobService: Failed to fetch job: ${responseData['message']}');
        return {
          'success': false,
          'job': null,
          'message': responseData['message'] ?? 'Failed to fetch job',
        };
      }
    } on DioException catch (e) {
      print('JobService: Failed to fetch job with DioException: ${e.message}');
      if (e.response != null) {
        print('JobService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'job': null,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('JobService: Failed to fetch job with general exception: $e');
      return {
        'success': false,
        'job': null,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get jobs posted by a specific recruiter
  Future<Map<String, dynamic>> getJobsByRecruiter(String recruiterId, {int page = 1, int limit = 10}) async {
    try {
      print('JobService: Fetching jobs for recruiter ID: $recruiterId, page: $page, limit: $limit');
      final response = await _dioClient.get('/api/jobs/by-recruiter/$recruiterId', params: {
        'page': page,
        'limit': limit,
      });
      final responseData = response.data;
      print('JobService: Jobs by recruiter response: $responseData');

      if (responseData.containsKey('jobs')) {
        final jobsData = List<Map<String, dynamic>>.from(responseData['jobs']);
        // Convert raw data to JobModel objects
        final jobModels = jobsData.map((jobData) => JobModel.fromJson(jobData)).toList();
        final pagination = responseData['pagination'] ?? {};
        print('JobService: Successfully fetched ${jobModels.length} jobs for recruiter $recruiterId');
        return {
          'success': true,
          'jobs': jobModels,
          'pagination': pagination,
          'message': 'Jobs fetched successfully',
        };
      } else {
        print('JobService: Failed to fetch jobs for recruiter: ${responseData['message']}');
        return {
          'success': false,
          'jobs': [],
          'pagination': {},
          'message': responseData['message'] ?? 'Failed to fetch jobs for recruiter',
        };
      }
    } on DioException catch (e) {
      print('JobService: Failed to fetch jobs by recruiter with DioException: ${e.message}');
      if (e.response != null) {
        print('JobService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'jobs': [],
        'pagination': {},
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('JobService: Failed to fetch jobs by recruiter with general exception: $e');
      return {
        'success': false,
        'jobs': [],
        'pagination': {},
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Delete job posting
  Future<Map<String, dynamic>> deleteJob(String jobId) async {
    try {
      final response = await _dioClient.delete('/api/jobs/$jobId');
      final responseData = response.data;

      if (responseData['success'] == true ||
          responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Job deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete job',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // Upload company logo
  Future<Map<String, dynamic>> uploadCompanyLogo(
    String jobId,
    String imagePath,
  ) async {
    try {
      final formData = FormData.fromMap({
        'logo': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dioClient.post(
        '/api/jobs/$jobId/upload-logo',
        data: formData,
      );
      final responseData = response.data;

      if (responseData['success'] == true ||
          responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'logo_url': responseData['logo_url'],
          'message':
              responseData['message'] ?? 'Company logo uploaded successfully',
        };
      } else {
        return {
          'success': false,
          'logo_url': null,
          'message': responseData['message'] ?? 'Failed to upload company logo',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'logo_url': null,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'logo_url': null,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get job categories
  Future<Map<String, dynamic>> getJobCategories() async {
    try {
      final response = await _dioClient.get('/api/jobs/categories');
      final responseData = response.data;

      if (responseData.containsKey('categories') ||
          responseData.containsKey('data')) {
        final categories = responseData['categories'] ?? responseData['data'];
        return {
          'success': true,
          'categories': categories is List ? categories.cast<String>() : [],
        };
      } else {
        return {
          'success': false,
          'categories': [],
          'message': responseData['message'] ?? 'Failed to fetch categories',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'categories': [],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'categories': [],
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get job locations
  Future<Map<String, dynamic>> getJobLocations() async {
    try {
      final response = await _dioClient.get('/api/jobs/locations');
      final responseData = response.data;

      if (responseData.containsKey('locations') ||
          responseData.containsKey('data')) {
        final locations = responseData['locations'] ?? responseData['data'];
        return {
          'success': true,
          'locations': locations is List ? locations.cast<String>() : [],
        };
      } else {
        return {
          'success': false,
          'locations': [],
          'message': responseData['message'] ?? 'Failed to fetch locations',
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'locations': [],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'locations': [],
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get all applications for a recruiter
  Future<Map<String, dynamic>> getApplicationsForRecruiter() async {
    try {
      print('JobService: Fetching all applications for the current recruiter');
      final response = await _dioClient.get('/api/applications/recruiter');
      final responseData = response.data;
      print('JobService: All applications for recruiter response: $responseData');

      if (responseData.containsKey('applications')) {
        final applicationsData = responseData['applications'] as List;
        return {
          'success': true,
          'applications': applicationsData,
          'pagination': responseData['pagination'],
        };
      } else {
        return {
          'success': false,
          'applications': [],
          'message': responseData['message'] ?? 'Failed to fetch applications',
        };
      }
    } on DioException catch (e) {
      print(
        'JobService: Failed to fetch applications with DioException: ${e.message}',
      );
      if (e.response != null) {
        print('JobService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'applications': [],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print(
        'JobService: Failed to fetch applications with general exception: $e',
      );
      return {
        'success': false,
        'applications': [],
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get applications for a specific job
  Future<Map<String, dynamic>> getApplicationsForJob(String jobId) async {
    try {
      print('JobService: Fetching applications for job ID: $jobId');
      final response = await _dioClient.get('/api/applications/job/$jobId');
      final responseData = response.data;
      print('JobService: Applications for job response: $responseData');

      if (responseData.containsKey('applications')) {
        final applicationsData = responseData['applications'] as List;
        return {
          'success': true,
          'applications': applicationsData,
          'pagination': responseData['pagination'],
        };
      } else {
        return {
          'success': false,
          'applications': [],
          'message': responseData['message'] ?? 'Failed to fetch applications',
        };
      }
    } on DioException catch (e) {
      print(
        'JobService: Failed to fetch applications with DioException: ${e.message}',
      );
      if (e.response != null) {
        print('JobService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'applications': [],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print(
        'JobService: Failed to fetch applications with general exception: $e',
      );
      return {
        'success': false,
        'applications': [],
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Update application status
  Future<Map<String, dynamic>> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    try {
      print(
        'JobService: Updating application $applicationId status to: $status',
      );
      final response = await _dioClient.put(
        '/api/applications/$applicationId/status',
        data: {'status': status},
      );
      final responseData = response.data;
      print('JobService: Update application status response: $responseData');

      if (responseData['success'] == true ||
          responseData['message']?.contains('successful') == true) {
        return {
          'success': true,
          'message':
              responseData['message'] ??
              'Application status updated successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to update application status',
        };
      }
    } on DioException catch (e) {
      print(
        'JobService: Failed to update application status with DioException: ${e.message}',
      );
      if (e.response != null) {
        print('JobService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print(
        'JobService: Failed to update application status with general exception: $e',
      );
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // Get complete jobseeker profile with all details
  Future<Map<String, dynamic>> getJobseekerProfile(String userId) async {
    try {
      print('JobService: Fetching jobseeker profile for user ID: $userId');
      final response = await _dioClient.get('/api/jobs/jobseeker/$userId');
      final responseData = response.data;
      print('JobService: Jobseeker profile response: $responseData');

      if (responseData.containsKey('jobseeker')) {
        final jobseekerData = responseData['jobseeker'];
        print('JobService: Successfully fetched jobseeker profile: ${jobseekerData['name']}');
        return {
          'success': true,
          'jobseeker': jobseekerData,
          'message': responseData['message'] ?? 'Jobseeker profile fetched successfully',
        };
      } else {
        print('JobService: Failed to fetch jobseeker profile: ${responseData['message']}');
        return {
          'success': false,
          'jobseeker': null,
          'message': responseData['message'] ?? 'Failed to fetch jobseeker profile',
        };
      }
    } on DioException catch (e) {
      print('JobService: Failed to fetch jobseeker profile with DioException: ${e.message}');
      if (e.response != null) {
        print('JobService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'jobseeker': null,
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('JobService: Failed to fetch jobseeker profile with general exception: $e');
      return {
        'success': false,
        'jobseeker': null,
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get latest jobs (most recently posted)
  Future<Map<String, dynamic>> getLatestJobs({
    int page = 1,
    int limit = 10,
    String? location,
    String? category,
    String? jobType,
  }) async {
    try {
      print('JobService: Fetching latest jobs - page: $page, limit: $limit');

      final params = <String, dynamic>{};
      params['page'] = page;
      params['limit'] = limit;
      if (location != null) params['location'] = location;
      if (category != null) params['category'] = category;
      if (jobType != null) params['job_type'] = jobType;

      final response = await _dioClient.get('/api/jobs/latest', params: params);
      final responseData = response.data;
      print('JobService: Latest jobs response received');

      if (responseData.containsKey('jobs')) {
        final jobsData = responseData['jobs'] as List;
        print('JobService: Raw latest jobs data count: ${jobsData.length}');

        // Parse each job individually
        final jobs = <JobModel>[];
        for (var jobData in jobsData) {
          try {
            final job = JobModel.fromJson(jobData);
            jobs.add(job);
          } catch (e) {
            print('JobService: Error parsing job ${jobData['id']}: $e');
          }
        }

        print('JobService: Successfully parsed ${jobs.length} latest jobs');
        return {
          'success': true,
          'jobs': jobs,
          'pagination': responseData['pagination'],
        };
      } else {
        print('JobService: Failed to fetch latest jobs: ${responseData['message']}');
        return {
          'success': false,
          'jobs': [],
          'message': responseData['message'] ?? 'Failed to fetch latest jobs',
        };
      }
    } on DioException catch (e) {
      print('JobService: Failed to fetch latest jobs with DioException: ${e.message}');
      if (e.response != null) {
        print('JobService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'jobs': [],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('JobService: Failed to fetch latest jobs with general exception: $e');
      return {
        'success': false,
        'jobs': [],
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get top companies by job count
  Future<Map<String, dynamic>> getTopCompanies({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('JobService: Fetching top companies - page: $page, limit: $limit');

      final params = <String, dynamic>{};
      params['page'] = page;
      params['limit'] = limit;

      final response = await _dioClient.get('/api/jobs/top-companies', params: params);
      final responseData = response.data;
      print('JobService: Top companies response received');

      if (responseData.containsKey('companies')) {
        final companiesData = responseData['companies'] as List;
        print('JobService: Raw top companies data count: ${companiesData.length}');

        return {
          'success': true,
          'companies': companiesData,
          'pagination': responseData['pagination'],
        };
      } else {
        print('JobService: Failed to fetch top companies: ${responseData['message']}');
        return {
          'success': false,
          'companies': [],
          'message': responseData['message'] ?? 'Failed to fetch top companies',
        };
      }
    } on DioException catch (e) {
      print('JobService: Failed to fetch top companies with DioException: ${e.message}');
      if (e.response != null) {
        print('JobService: Response data: ${e.response!.data}');
      }
      return {
        'success': false,
        'companies': [],
        'message': e.response?.data['message'] ?? 'Network error occurred',
      };
    } catch (e) {
      print('JobService: Failed to fetch top companies with general exception: $e');
      return {
        'success': false,
        'companies': [],
        'message': 'An unexpected error occurred',
      };
    }
  }
}