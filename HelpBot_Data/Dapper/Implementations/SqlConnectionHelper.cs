using System;
using System.Data;
using Microsoft.Data.SqlClient;
using HelpBot_Data.Dapper.Interfaces;

namespace HelpBot_Data.Dapper.Implementations
{
    public class SqlConnectionHelper : ISqlConnectionHelper
    {
        private readonly string _connectionString;
        private IDbConnection? _connection;

        public SqlConnectionHelper(string connectionString)
        {
            _connectionString = connectionString;
        }

        public IDbConnection GetDbConnection()
        {
            if (_connection == null || _connection.State != ConnectionState.Open)
            {
                _connection = new SqlConnection(_connectionString);
                _connection.Open();
            }
            return _connection;
        }

        public void Dispose()
        {
            if (_connection != null)
            {
                if (_connection.State == ConnectionState.Open)
                {
                    _connection.Close();
                }
                _connection.Dispose();
                _connection = null;
            }
            GC.SuppressFinalize(this);
        }
    }
}
