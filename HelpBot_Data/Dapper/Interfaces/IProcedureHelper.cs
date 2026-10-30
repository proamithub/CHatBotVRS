using System.Collections.Generic;
using System.Threading.Tasks;

namespace HelpBot_Data.Dapper.Interfaces
{
    public interface IProcedureHelper
    {
        Task<IEnumerable<T>> QueryAsync<T>(string storedProcedure, object? parameters = null);
        Task<T?> QueryFirstOrDefaultAsync<T>(string storedProcedure, object? parameters = null);
        Task<int> ExecuteCommandAsync(string storedProcedure, object? parameters = null);
    }
}
