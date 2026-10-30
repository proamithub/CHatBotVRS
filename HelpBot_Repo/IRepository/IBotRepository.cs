using System.Collections.Generic;
using System.Threading.Tasks;
using HelpBot_Model.DTO;

namespace HelpBot_Repo.IRepository
{
    public interface IBotRepository
    {
        Task<IEnumerable<BotQuestionDTO>> GetBotQuestionsAsync();
        Task<IEnumerable<ComplaintTypeDTO>> GetComplaintTypesAsync();
        Task<TicketDetailDTO?> CreateTicketAsync(CreateTicketRequestDTO request);
        Task<IEnumerable<TicketDetailDTO>> GetTicketStatusAsync(string searchTerm);
        Task<SessionStepResultDTO?> SaveBotResponseAsync(SaveResponseRequestDTO request);
    }
}
