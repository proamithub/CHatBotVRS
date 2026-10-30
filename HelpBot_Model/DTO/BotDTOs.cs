namespace HelpBot_Model.DTO
{
    public class BotQuestionDTO
    {
        public int QuestionId { get; set; }
        public string QuestionText { get; set; } = string.Empty;
        public int StepOrder { get; set; }
        public string FieldKey { get; set; } = string.Empty;
        public string InputType { get; set; } = "text";
        public bool IsActive { get; set; }
    }

    public class ComplaintTypeDTO
    {
        public int CTypeID { get; set; }
        public string TypeName { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public int Sequence { get; set; }
    }

    public class CreateTicketRequestDTO
    {
        public string Name { get; set; } = string.Empty;
        public string Mobile { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Enroll_Roll { get; set; } = string.Empty;
        public int CTypeID { get; set; } = 0;
        public string Subject { get; set; } = string.Empty;
        public int FlagTypeID { get; set; } = 1;
    }

    public class TicketDetailDTO
    {
        public long EntryID { get; set; }
        public string TicketID { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Mobile { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Enroll_Roll { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string Priority { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string Subject { get; set; } = string.Empty;
        public DateTime CreatedDate { get; set; }
    }

    public class SaveResponseRequestDTO
    {
        public Guid SessionId { get; set; }
        public int QuestionId { get; set; }
        public string AnswerText { get; set; } = string.Empty;
    }

    public class SessionStepResultDTO
    {
        public int CurrentStep { get; set; }
        public bool IsCompleted { get; set; }
    }
}
