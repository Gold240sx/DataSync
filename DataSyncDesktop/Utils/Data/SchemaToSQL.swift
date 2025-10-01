//
//  SchemaToSQL.swift
//  DataSync
//
//  Created by Michael Martell on 10/1/25.
//

import Foundation

// Convert the schema file to compatible SQL commands for Supabase
// This ensures database schema consistency between Swift and Supabase

/*
 RULES
 1. always use if table does not exist..
 2. use begin and end transactions
 3. use the schema file to create the SQL command
 4. start with enums, then functions, then tables, then relationships, lastly RLS. keep these all seperate.
 5. schema should only include values that are either synced to .all or to .supabase
 */

/// Maps Swift data types to PostgreSQL data types
private func postgresDataType(for swiftType: String) -> String {
    switch swiftType {
    case "String":
        return "TEXT"
    case "Int":
        return "INTEGER"
    case "Double":
        return "DOUBLE PRECISION"
    case "Bool":
        return "BOOLEAN"
    case "Date":
        return "TIMESTAMP WITH TIME ZONE"
    case "UUID":
        return "UUID"
    case "Data":
        return "BYTEA"
    default:
        return "TEXT" // Default fallback
    }
}

/// Generates SQL for a single table schema
private func generateTableSQL(from tableSchema: TableSchema) -> String {
    var sql = ""
    
    // Only include fields that are synced with Supabase
    let supabaseFields = tableSchema.values.filter { value in
        return value.syncOptions.contains(.supabase)
    }
    
    if supabaseFields.isEmpty {
        return "" // Skip tables with no Supabase-synced fields
    }
    
    // Create table if it doesn't exist
    sql += "-- Create table \(tableSchema.tableName) if it doesn't exist\n"
    sql += "CREATE TABLE IF NOT EXISTS \(tableSchema.tableName) (\n"
    
    // Add fields
    let fieldDefinitions = supabaseFields.map { value in
        let dataType = postgresDataType(for: value.dataType)
        let uniqueConstraint = value.unique ? " UNIQUE" : ""
        let primaryKeyConstraint = value.name == tableSchema.primaryKey ? " PRIMARY KEY" : ""
        let notNullConstraint = value.name == tableSchema.primaryKey ? " NOT NULL" : ""
        
        return "    \(value.name) \(dataType)\(notNullConstraint)\(uniqueConstraint)\(primaryKeyConstraint)"
    }
    
    sql += fieldDefinitions.joined(separator: ",\n")
    sql += "\n);\n\n"
    
    // Add comments for encrypted fields
    let encryptedFields = supabaseFields.filter { $0.encrypted }
    if !encryptedFields.isEmpty {
        sql += "-- Fields marked as encrypted in the client application\n"
        for field in encryptedFields {
            sql += "COMMENT ON COLUMN \(tableSchema.tableName).\(field.name) IS 'This field is encrypted on the client';\n"
        }
        sql += "\n"
    }
    
    return sql
}

/// Converts schema definitions to SQL commands for Supabase
public func schemaToSQL(_ schemaName: String) -> String {
    var sql = "-- Generated SQL for Supabase from DataSync schema: \(schemaName)\n"
    sql += "-- Generated on: \(Date())\n\n"
    
    // Begin transaction
    sql += "BEGIN;\n\n"
    
    // Get all schemas from the registry
    let allSchemas = DataSchemaRegistry.shared.tableSchemas
    
    // Generate SQL for each table
    for schema in allSchemas {
        let tableSql = generateTableSQL(from: schema)
        if !tableSql.isEmpty {
            sql += tableSql
        }
    }
    
    // Add indexes for performance
    sql += "-- Create indexes for better query performance\n"
    for schema in allSchemas {
        if generateTableSQL(from: schema).isEmpty {
            continue // Skip tables with no Supabase fields
        }
        
        // Add index on primary key if not already a primary key constraint
        let tableName = schema.tableName
        let primaryKey = schema.primaryKey
        let primaryKeyStr = String(describing: primaryKey)
        sql += "CREATE INDEX IF NOT EXISTS idx_\(tableName)_\(primaryKeyStr) ON \(tableName)(\(primaryKeyStr));\n"
        
        // Add indexes on fields that might be frequently queried
        let supabaseFields = schema.values.filter { value in
            return value.syncOptions.contains(.supabase) && value.name != schema.primaryKey
        }
        
        for field in supabaseFields {
            if field.name.hasSuffix("_id") || field.name.contains("name") || field.name.contains("date") {
                sql += "CREATE INDEX IF NOT EXISTS idx_\(schema.tableName)_\(field.name) ON \(schema.tableName)(\(field.name));\n"
            }
        }
        sql += "\n"
    }
    
    // End transaction
    sql += "COMMIT;\n"
    
    return sql
}

/// Generates SQL for all schemas in the registry
public func generateAllSchemasSQL() -> String {
    return schemaToSQL("AllSchemas")
}

/// Generates SQL for a specific schema by table name
public func generateSchemaSQL(forTable tableName: String) -> String {
    if DataSchemaRegistry.shared.schema(for: tableName) != nil {
        return schemaToSQL(tableName)
    }
    return "-- Schema not found for table: \(tableName)"
}

/// Detects and generates foreign key relationships based on field naming conventions
public func generateForeignKeySQL() -> String {
    var sql = "-- Foreign Key Relationships\n\n"
    sql += "BEGIN;\n\n"
    
    let allSchemas = DataSchemaRegistry.shared.tableSchemas
    let tableNames = allSchemas.map { $0.tableName }
    
    for schema in allSchemas {
        let supabaseFields = schema.values.filter { $0.syncOptions.contains(.supabase) }
        
        for field in supabaseFields {
            // Look for fields that end with _id and might be foreign keys
            if field.name.hasSuffix("_id") && field.name != schema.primaryKey {
                // Extract the potential table name from the field
                let potentialTableName = String(field.name.dropLast(3)) // Remove "_id"
                
                // Check if this is a plural form (users_id -> user)
                var singularTableName = potentialTableName
                if potentialTableName.hasSuffix("s") {
                    singularTableName = String(potentialTableName.dropLast())
                }
                
                // Check if either form exists as a table
                if tableNames.contains(potentialTableName) || tableNames.contains(singularTableName) {
                    let referencedTable = tableNames.contains(potentialTableName) ? potentialTableName : singularTableName
                    
                    // Find the referenced table's primary key
                    if let referencedSchema = allSchemas.first(where: { $0.tableName == referencedTable }) {
                        let referencedPK = referencedSchema.primaryKey
                        
                        // Generate foreign key constraint
                        let tableName = schema.tableName
                        let fieldName = field.name
                        sql += "ALTER TABLE \(tableName) ADD CONSTRAINT fk_\(tableName)_\(fieldName)\n"
                        let referencedPKStr = String(describing: referencedPK)
                        sql += "    FOREIGN KEY (\(fieldName)) REFERENCES \(referencedTable)(\(referencedPKStr)) ON DELETE CASCADE;\n\n"
                    }
                }
            }
        }
    }
    
    sql += "COMMIT;\n"
    return sql
}

/// Generates Row Level Security (RLS) policies for tables
public func generateRLSPoliciesSQL() -> String {
    var sql = "-- Setup Row Level Security policies\n"
    sql += "BEGIN;\n\n"
    
    let allSchemas = DataSchemaRegistry.shared.tableSchemas
    
    for schema in allSchemas {
        if generateTableSQL(from: schema).isEmpty {
            continue // Skip tables with no Supabase fields
        }
        
        let tableName = schema.tableName
        sql += "ALTER TABLE \(tableName) ENABLE ROW LEVEL SECURITY;\n"
        
        // Special handling for user tables
        if tableName.contains("user") {
            // For user tables, users can only access their own data
            // tableName is already defined above
            let primaryKey = schema.primaryKey
            let primaryKeyStr = String(describing: primaryKey)
            
            sql += "-- Users can only access their own data\n"
            sql += "CREATE POLICY \"\(tableName)_auth_select\" ON \(tableName) FOR SELECT\n"
            sql += "    USING (auth.uid()::text = \(primaryKeyStr)::text);\n\n"
            
            sql += "CREATE POLICY \"\(tableName)_auth_insert\" ON \(tableName) FOR INSERT\n"
            sql += "    WITH CHECK (auth.uid()::text = \(primaryKeyStr)::text);\n\n"
            
            sql += "CREATE POLICY \"\(tableName)_auth_update\" ON \(tableName) FOR UPDATE\n"
            sql += "    USING (auth.uid()::text = \(primaryKeyStr)::text);\n\n"
            
            sql += "CREATE POLICY \"\(tableName)_auth_delete\" ON \(tableName) FOR DELETE\n"
            sql += "    USING (auth.uid()::text = \(primaryKeyStr)::text);\n\n"
        } else {
            // For other tables, use a more general approach with user_id field if it exists
            let hasUserIdField = schema.values.contains { $0.name == "user_id" || $0.name == "owner_id" }
            
            if hasUserIdField {
                sql += "-- Resources owned by users\n"
                sql += "CREATE POLICY \"\(tableName)_auth_select\" ON \(tableName) FOR SELECT\n"
                sql += "    USING (auth.uid()::text = user_id::text);\n\n"
                
                sql += "CREATE POLICY \"\(tableName)_auth_insert\" ON \(tableName) FOR INSERT\n"
                sql += "    WITH CHECK (auth.uid()::text = user_id::text);\n\n"
                
                sql += "CREATE POLICY \"\(tableName)_auth_update\" ON \(tableName) FOR UPDATE\n"
                sql += "    USING (auth.uid()::text = user_id::text);\n\n"
                
                sql += "CREATE POLICY \"\(tableName)_auth_delete\" ON \(tableName) FOR DELETE\n"
                sql += "    USING (auth.uid()::text = user_id::text);\n\n"
            } else {
                // Default policy for tables without user_id - restrict to authenticated users
                sql += "-- Default policies for authenticated users\n"
                sql += "CREATE POLICY \"\(tableName)_auth_select\" ON \(tableName) FOR SELECT\n"
                sql += "    USING (auth.role() = 'authenticated');\n\n"
                
                sql += "CREATE POLICY \"\(tableName)_auth_insert\" ON \(tableName) FOR INSERT\n"
                sql += "    WITH CHECK (auth.role() = 'authenticated');\n\n"
                
                sql += "CREATE POLICY \"\(tableName)_auth_update\" ON \(tableName) FOR UPDATE\n"
                sql += "    USING (auth.role() = 'authenticated');\n\n"
                
                sql += "CREATE POLICY \"\(tableName)_auth_delete\" ON \(tableName) FOR DELETE\n"
                sql += "    USING (auth.role() = 'authenticated');\n\n"
            }
        }
    }
    
    sql += "COMMIT;\n"
    return sql
}

/// Generates a complete SQL script for Supabase setup
public func generateCompleteSupabaseSQL() -> String {
    var sql = "-- Complete Supabase Setup Script\n"
    sql += "-- Generated on: \(Date())\n\n"
    
    // 1. Add table definitions (first)
    sql += generateAllSchemasSQL()
    
    // 2. Add foreign key relationships (second)
    sql += "\n" + generateForeignKeySQL()
    
    // 3. Add any custom SQL functions or triggers (third)
    sql += "\n-- Custom Functions and Triggers\n\n"
    sql += "BEGIN;\n\n"
    
    // Example: Add updated_at trigger function
    sql += "-- Function to automatically update updated_at timestamp\n"
    sql += "CREATE OR REPLACE FUNCTION update_modified_column()\n"
    sql += "RETURNS TRIGGER AS $$\n"
    sql += "BEGIN\n"
    sql += "    NEW.updated_at = now();\n"
    sql += "    RETURN NEW;\n"
    sql += "END;\n"
    sql += "$$ language 'plpgsql';\n\n"
    
    // Apply the trigger to tables with updated_at column
    let allSchemas = DataSchemaRegistry.shared.tableSchemas
    for schema in allSchemas {
        let hasUpdatedAt = schema.values.contains { $0.name == "updated_at" }
        if hasUpdatedAt {
            sql += "-- Add updated_at trigger for \(schema.tableName)\n"
            sql += "DROP TRIGGER IF EXISTS set_\(schema.tableName)_updated_at ON \(schema.tableName);\n"
            sql += "CREATE TRIGGER set_\(schema.tableName)_updated_at\n"
            sql += "BEFORE UPDATE ON \(schema.tableName)\n"
            sql += "FOR EACH ROW\n"
            sql += "EXECUTE FUNCTION update_modified_column();\n\n"
        }
    }
    
    sql += "COMMIT;\n"
    
    // 4. Add RLS policies (last)
    sql += "\n" + generateRLSPoliciesSQL()
    
    return sql
}

