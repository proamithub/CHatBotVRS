using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Dapper;
using HelpBot_Data.Dapper.Interfaces;

namespace HelpBot_Data.Dapper.Implementations
{
    public class ProcedureHelper : IProcedureHelper
    {
        private readonly ISqlConnectionHelper _sqlConnectionProvider;

        public ProcedureHelper(ISqlConnectionHelper sqlConnectionProvider)
        {
            _sqlConnectionProvider = sqlConnectionProvider;
        }

        public async Task<IEnumerable<T>> QueryAsync<T>(string storedProcedure, object? parameters = null)
        {
            using (var connection = _sqlConnectionProvider.GetDbConnection())
            {
                return await connection.QueryAsync<T>(
                    storedProcedure, 
                    parameters, 
                    commandType: CommandType.StoredProcedure
                );
            }
        }

        public async Task<T?> QueryFirstOrDefaultAsync<T>(string storedProcedure, object? parameters = null)
        {
            using (var connection = _sqlConnectionProvider.GetDbConnection())
            {
                return await connection.QueryFirstOrDefaultAsync<T>(
                    storedProcedure, 
                    parameters, 
                    commandType: CommandType.StoredProcedure
                );
            }
        }

        public async Task<int> ExecuteCommandAsync(string storedProcedure, object? parameters = null)
        {
            using (var connection = _sqlConnectionProvider.GetDbConnection())
            {
                return await connection.ExecuteAsync(
                    storedProcedure, 
                    parameters, 
                    commandType: CommandType.StoredProcedure
                );
            }
        }
    }
}
