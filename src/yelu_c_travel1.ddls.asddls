@EndUserText.label: 'Consumption/Projection View on Travel'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity YELU_C_TRAVEL1 
as projection on YELU_I_TRAVEL1
{
    key TravelID,
    AgencyID,
    CustomerID,
    BeginDate,
    EndDate,
    BookingFee,
    TotalPrice,
    CurrencyCode,
    Description,
    OverallStatus,
    Attachment,
    MimeType,
    Filename,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt
}
