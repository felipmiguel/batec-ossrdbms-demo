using System.ComponentModel.DataAnnotations;

namespace SimpleTodo.Repo;

public class TodoList
{
    public TodoList(string name)
    {
        Name = name;
    }

    [Key]
    public Guid? Id { get; set; }
    public string Name { get; set; }
    public string? Description { get; set; }
    public DateTimeOffset CreatedDate { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedDate { get; set; }
}