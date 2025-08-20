// Advanced API documentation system for exceptional code documentation
// This demonstrates comprehensive API documentation generation with examples and validation

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// API documentation generator for creating comprehensive developer docs
class ApiDocumentationGenerator {
  static final ApiDocumentationGenerator _instance = ApiDocumentationGenerator._internal();
  factory ApiDocumentationGenerator() => _instance;
  ApiDocumentationGenerator._internal();

  static ApiDocumentationGenerator get instance => _instance;

  final Map<String, ApiEndpoint> _endpoints = {};
  final Map<String, DataModel> _models = {};
  final Map<String, ErrorDefinition> _errors = {};

  /// Register an API endpoint for documentation
  void registerEndpoint(ApiEndpoint endpoint) {
    _endpoints[endpoint.id] = endpoint;
  }

  /// Register a data model for documentation
  void registerModel(DataModel model) {
    _models[model.name] = model;
  }

  /// Register an error definition for documentation
  void registerError(ErrorDefinition error) {
    _errors[error.code] = error;
  }

  /// Generate comprehensive API documentation
  Future<String> generateDocumentation({
    String title = 'ExpenseTracker API Documentation',
    String version = '1.0.0',
    bool includeExamples = true,
    bool includeErrorCodes = true,
  }) async {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('# $title');
    buffer.writeln('Version: $version');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    // Table of Contents
    buffer.writeln('## Table of Contents');
    buffer.writeln('1. [Overview](#overview)');
    buffer.writeln('2. [Data Models](#data-models)');
    buffer.writeln('3. [API Endpoints](#api-endpoints)');
    if (includeErrorCodes) {
      buffer.writeln('4. [Error Codes](#error-codes)');
    }
    buffer.writeln('5. [Examples](#examples)');
    buffer.writeln();

    // Overview
    buffer.writeln('## Overview');
    buffer.writeln('This documentation describes the ExpenseTracker application API.');
    buffer.writeln('The API follows Clean Architecture principles with domain-driven design.');
    buffer.writeln();

    // Data Models
    buffer.writeln('## Data Models');
    for (final model in _models.values) {
      buffer.writeln(_generateModelDocumentation(model));
    }

    // API Endpoints
    buffer.writeln('## API Endpoints');
    for (final endpoint in _endpoints.values) {
      buffer.writeln(_generateEndpointDocumentation(endpoint, includeExamples));
    }

    // Error Codes
    if (includeErrorCodes) {
      buffer.writeln('## Error Codes');
      for (final error in _errors.values) {
        buffer.writeln(_generateErrorDocumentation(error));
      }
    }

    return buffer.toString();
  }

  /// Generate OpenAPI specification
  Map<String, dynamic> generateOpenApiSpec({
    String title = 'ExpenseTracker API',
    String version = '1.0.0',
    String description = 'ExpenseTracker application API',
  }) {
    return {
      'openapi': '3.0.0',
      'info': {
        'title': title,
        'version': version,
        'description': description,
      },
      'paths': _endpoints.values.fold<Map<String, dynamic>>({}, (paths, endpoint) {
        paths[endpoint.path] = {
          endpoint.method.toLowerCase(): {
            'summary': endpoint.summary,
            'description': endpoint.description,
            'parameters': endpoint.parameters.map((p) => p.toOpenApi()).toList(),
            'responses': endpoint.responses.map((r) => r.toOpenApi()).toList(),
            'tags': endpoint.tags,
          },
        };
        return paths;
      }),
      'components': {
        'schemas': _models.values.fold<Map<String, dynamic>>({}, (schemas, model) {
          schemas[model.name] = model.toOpenApiSchema();
          return schemas;
        }),
      },
    };
  }

  String _generateModelDocumentation(DataModel model) {
    final buffer = StringBuffer();

    buffer.writeln('### ${model.name}');
    buffer.writeln(model.description);
    buffer.writeln();

    buffer.writeln('**Properties:**');
    for (final property in model.properties) {
      buffer.writeln('- `${property.name}` (${property.type}): ${property.description}');
      if (property.isRequired) {
        buffer.writeln('  - **Required**');
      }
      if (property.validation != null) {
        buffer.writeln('  - **Validation:** ${property.validation}');
      }
    }
    buffer.writeln();

    if (model.example != null) {
      buffer.writeln('**Example:**');
      buffer.writeln('```json');
      buffer.writeln(jsonEncode(model.example));
      buffer.writeln('```');
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _generateEndpointDocumentation(ApiEndpoint endpoint, bool includeExamples) {
    final buffer = StringBuffer();

    buffer.writeln('### ${endpoint.method} ${endpoint.path}');
    buffer.writeln(endpoint.description);
    buffer.writeln();

    if (endpoint.parameters.isNotEmpty) {
      buffer.writeln('**Parameters:**');
      for (final param in endpoint.parameters) {
        buffer.writeln('- `${param.name}` (${param.type}): ${param.description}');
        if (param.isRequired) {
          buffer.writeln('  - **Required**');
        }
        if (param.defaultValue != null) {
          buffer.writeln('  - **Default:** ${param.defaultValue}');
        }
      }
      buffer.writeln();
    }

    if (endpoint.responses.isNotEmpty) {
      buffer.writeln('**Responses:**');
      for (final response in endpoint.responses) {
        buffer.writeln('- **${response.statusCode}** (${response.description})');
        if (response.schema != null) {
          buffer.writeln('  - Schema: ${response.schema}');
        }
      }
      buffer.writeln();
    }

    if (includeExamples && endpoint.examples.isNotEmpty) {
      buffer.writeln('**Examples:**');
      for (final example in endpoint.examples) {
        buffer.writeln('#### ${example.title}');
        if (example.request != null) {
          buffer.writeln('**Request:**');
          buffer.writeln('```json');
          buffer.writeln(jsonEncode(example.request));
          buffer.writeln('```');
        }
        if (example.response != null) {
          buffer.writeln('**Response:**');
          buffer.writeln('```json');
          buffer.writeln(jsonEncode(example.response));
          buffer.writeln('```');
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  String _generateErrorDocumentation(ErrorDefinition error) {
    final buffer = StringBuffer();

    buffer.writeln('### ${error.code}');
    buffer.writeln('**Message:** ${error.message}');
    buffer.writeln('**Description:** ${error.description}');
    buffer.writeln('**HTTP Status:** ${error.httpStatus}');

    if (error.possibleCauses.isNotEmpty) {
      buffer.writeln('**Possible Causes:**');
      for (final cause in error.possibleCauses) {
        buffer.writeln('- $cause');
      }
    }

    if (error.solutions.isNotEmpty) {
      buffer.writeln('**Solutions:**');
      for (final solution in error.solutions) {
        buffer.writeln('- $solution');
      }
    }

    buffer.writeln();
    return buffer.toString();
  }

  /// Save documentation to file
  Future<void> saveDocumentationToFile(String documentation, String filePath) async {
    if (kDebugMode) {
      final file = File(filePath);
      await file.writeAsString(documentation);
      print('Documentation saved to: $filePath');
    }
  }
}

/// API endpoint definition for documentation
class ApiEndpoint {
  final String id;
  final String method;
  final String path;
  final String summary;
  final String description;
  final List<ApiParameter> parameters;
  final List<ApiResponse> responses;
  final List<String> tags;
  final List<ApiExample> examples;

  ApiEndpoint({
    required this.id,
    required this.method,
    required this.path,
    required this.summary,
    required this.description,
    this.parameters = const [],
    this.responses = const [],
    this.tags = const [],
    this.examples = const [],
  });
}

/// API parameter definition
class ApiParameter {
  final String name;
  final String type;
  final String description;
  final bool isRequired;
  final dynamic defaultValue;
  final String location; // query, path, header, body

  ApiParameter({
    required this.name,
    required this.type,
    required this.description,
    this.isRequired = false,
    this.defaultValue,
    this.location = 'query',
  });

  Map<String, dynamic> toOpenApi() {
    return {
      'name': name,
      'in': location,
      'description': description,
      'required': isRequired,
      'schema': {'type': type},
      if (defaultValue != null) 'default': defaultValue,
    };
  }
}

/// API response definition
class ApiResponse {
  final int statusCode;
  final String description;
  final String? schema;
  final Map<String, dynamic>? example;

  ApiResponse({
    required this.statusCode,
    required this.description,
    this.schema,
    this.example,
  });

  Map<String, dynamic> toOpenApi() {
    return {
      statusCode.toString(): {
        'description': description,
        if (schema != null) 'content': {
          'application/json': {
            'schema': {'type': schema},
            if (example != null) 'example': example,
          },
        },
      },
    };
  }
}

/// API example definition
class ApiExample {
  final String title;
  final String? description;
  final Map<String, dynamic>? request;
  final Map<String, dynamic>? response;

  ApiExample({
    required this.title,
    this.description,
    this.request,
    this.response,
  });
}

/// Data model definition for documentation
class DataModel {
  final String name;
  final String description;
  final List<ModelProperty> properties;
  final Map<String, dynamic>? example;
  final List<String> validationRules;

  DataModel({
    required this.name,
    required this.description,
    required this.properties,
    this.example,
    this.validationRules = const [],
  });

  Map<String, dynamic> toOpenApiSchema() {
    return {
      'type': 'object',
      'description': description,
      'properties': properties.fold<Map<String, dynamic>>({}, (props, property) {
        props[property.name] = {
          'type': property.type,
          'description': property.description,
          if (property.format != null) 'format': property.format,
          if (property.validation != null) 'pattern': property.validation,
        };
        return props;
      }),
      'required': properties.where((p) => p.isRequired).map((p) => p.name).toList(),
      if (example != null) 'example': example,
    };
  }
}

/// Model property definition
class ModelProperty {
  final String name;
  final String type;
  final String description;
  final bool isRequired;
  final String? format;
  final String? validation;
  final dynamic defaultValue;

  ModelProperty({
    required this.name,
    required this.type,
    required this.description,
    this.isRequired = false,
    this.format,
    this.validation,
    this.defaultValue,
  });
}

/// Error definition for documentation
class ErrorDefinition {
  final String code;
  final String message;
  final String description;
  final int httpStatus;
  final List<String> possibleCauses;
  final List<String> solutions;

  ErrorDefinition({
    required this.code,
    required this.message,
    required this.description,
    required this.httpStatus,
    this.possibleCauses = const [],
    this.solutions = const [],
  });
}

/// Documentation builder for easy setup
class DocumentationBuilder {
  static void setupExpenseTrackerDocumentation() {
    final generator = ApiDocumentationGenerator.instance;

    // Register Expense model
    generator.registerModel(DataModel(
      name: 'Expense',
      description: 'Represents a financial transaction (expense or income)',
      properties: [
        ModelProperty(
          name: 'id',
          type: 'string',
          description: 'Unique identifier for the expense',
          isRequired: true,
          format: 'uuid',
        ),
        ModelProperty(
          name: 'title',
          type: 'string',
          description: 'Short title describing the expense',
          isRequired: true,
          validation: r'^.{1,100}$',
        ),
        ModelProperty(
          name: 'amount',
          type: 'number',
          description: 'Amount of the transaction',
          isRequired: true,
          format: 'double',
          validation: r'^\d+\.\d{2}$',
        ),
        ModelProperty(
          name: 'category',
          type: 'string',
          description: 'Category of the expense',
          isRequired: true,
        ),
        ModelProperty(
          name: 'type',
          type: 'string',
          description: 'Type of transaction',
          isRequired: true,
          validation: r'^(expense|income)$',
        ),
        ModelProperty(
          name: 'date',
          type: 'string',
          description: 'Date of the transaction',
          isRequired: true,
          format: 'date-time',
        ),
      ],
      example: {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'title': 'Lunch at restaurant',
        'amount': 25.50,
        'category': 'Food',
        'type': 'expense',
        'date': '2024-01-15T12:30:00.000Z',
      },
    ));

    // Register FinancialGoal model
    generator.registerModel(DataModel(
      name: 'FinancialGoal',
      description: 'Represents a financial savings goal',
      properties: [
        ModelProperty(
          name: 'id',
          type: 'string',
          description: 'Unique identifier for the goal',
          isRequired: true,
          format: 'uuid',
        ),
        ModelProperty(
          name: 'title',
          type: 'string',
          description: 'Title of the financial goal',
          isRequired: true,
        ),
        ModelProperty(
          name: 'targetAmount',
          type: 'number',
          description: 'Target amount to save',
          isRequired: true,
          format: 'double',
        ),
        ModelProperty(
          name: 'currentAmount',
          type: 'number',
          description: 'Current saved amount',
          isRequired: true,
          format: 'double',
        ),
        ModelProperty(
          name: 'status',
          type: 'string',
          description: 'Current status of the goal',
          isRequired: true,
          validation: r'^(active|completed|paused)$',
        ),
      ],
      example: {
        'id': '456e7890-e12b-34c5-b678-901234567890',
        'title': 'Emergency Fund',
        'targetAmount': 10000.00,
        'currentAmount': 2500.00,
        'status': 'active',
      },
    ));

    // Register common errors
    generator.registerError(ErrorDefinition(
      code: 'EXPENSE_NOT_FOUND',
      message: 'Expense not found',
      description: 'The requested expense does not exist',
      httpStatus: 404,
      possibleCauses: [
        'Expense ID is invalid',
        'Expense has been deleted',
        'User does not have access to this expense',
      ],
      solutions: [
        'Verify the expense ID is correct',
        'Check if the expense still exists',
        'Ensure proper authentication',
      ],
    ));

    generator.registerError(ErrorDefinition(
      code: 'VALIDATION_ERROR',
      message: 'Validation failed',
      description: 'Input data failed validation checks',
      httpStatus: 400,
      possibleCauses: [
        'Required fields are missing',
        'Data format is incorrect',
        'Values are outside allowed ranges',
      ],
      solutions: [
        'Check all required fields are provided',
        'Verify data formats match specifications',
        'Ensure values are within valid ranges',
      ],
    ));
  }
}

/// Extension methods for easy documentation generation
extension DocumentationExtensions on Object {
  /// Generate documentation for this class
  Future<void> generateDocumentation({
    String? outputPath,
    bool includeExamples = true,
  }) async {
    final generator = ApiDocumentationGenerator.instance;
    final documentation = await generator.generateDocumentation(
      includeExamples: includeExamples,
    );

    if (outputPath != null) {
      await generator.saveDocumentationToFile(documentation, outputPath);
    } else if (kDebugMode) {
      print(documentation);
    }
  }
}