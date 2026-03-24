using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TaskApp.Infrastructure.Migrations
{
    public partial class AddUserLastLogin : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "LastLogin",
                table: "Users",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LastLogin",
                table: "Users");
        }
    }
}
