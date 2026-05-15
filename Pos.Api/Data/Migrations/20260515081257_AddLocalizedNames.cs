using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Pos.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddLocalizedNames : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AltLanguageCode",
                table: "Products",
                type: "nvarchar(8)",
                maxLength: 8,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "NameLocalized",
                table: "Products",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AltLanguageCode",
                table: "Categories",
                type: "nvarchar(8)",
                maxLength: 8,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "NameLocalized",
                table: "Categories",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AltLanguageCode",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "NameLocalized",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "AltLanguageCode",
                table: "Categories");

            migrationBuilder.DropColumn(
                name: "NameLocalized",
                table: "Categories");
        }
    }
}
