using System.Collections.Generic;
using System.Threading.Tasks;
using HelpBot_Data.Dapper;
using HelpBot_Model.DTO;
using HelpBot_Repo.IRepository;

namespace HelpBot_Repo.Repository
{
    public class BotRepository : IBotRepository
    {
        private readonly IDapperContext _dapperContext;

        public BotRepository(IDapperContext dapperContext)
        {
            _dapperContext = dapperContext;
        }

        public async Task<IEnumerable<BotQuestionDTO>> GetBotQuestionsAsync()
        {
            return await _dapperContext.ProcedureHelper.QueryAsync<BotQuestionDTO>("dbo.sp_GetBotQuestions");
        }

        public async Task<IEnumerable<ComplaintTypeDTO>> GetComplaintTypesAsync()
        {
            return await _dapperContext.ProcedureHelper.QueryAsync<ComplaintTypeDTO>("dbo.sp_GetComplaintTypes");
        }

        public async Task<TicketDetailDTO?> CreateTicketAsync(CreateTicketRequestDTO request)
        {
            var parameters = new
            {
                request.Name,
                request.Mobile,
                request.Email,
                request.Enroll_Roll,
                request.CTypeID,
                request.Subject,
                request.FlagTypeID
            };

            return await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<TicketDetailDTO>(
                "dbo.sp_CreateTicket", 
                parameters
            );
        }

        public async Task<IEnumerable<TicketDetailDTO>> GetTicketStatusAsync(string searchTerm)
        {
            var parameters = new { SearchTerm = searchTerm };
            return await _dapperContext.ProcedureHelper.QueryAsync<TicketDetailDTO>(
                "dbo.sp_GetTicketStatus", 
                parameters
            );
        }

        public async Task<SessionStepResultDTO?> SaveBotResponseAsync(SaveResponseRequestDTO request)
        {
            var parameters = new
            {
                request.SessionId,
                request.QuestionId,
                request.AnswerText
            };

            return await _dapperContext.ProcedureHelper.QueryFirstOrDefaultAsync<SessionStepResultDTO>(
                "dbo.sp_SaveBotResponse", 
                parameters
            );
        }
    }
}
