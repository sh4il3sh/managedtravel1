@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View on Table Booking'
define root view entity YELU_I_TRAVEL1
  as select from yelu_travel1
{
  key travel_id             as TravelID,
      agency_id             as AgencyID,
      customer_id           as CustomerID,
      begin_date            as BeginDate,
      end_date              as EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_fee           as BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price           as TotalPrice,
      currency_code         as CurrencyCode,
      description           as Description,
      overall_status        as OverallStatus,
      @Semantics.largeObject: {
          mimeType: 'MimeType',
          fileName: 'Filename',
          acceptableMimeTypes: [ 'image/png','image/jpeg', 'video/mp4' ],
          contentDispositionPreference: #ATTACHMENT
      }
      attachment            as Attachment,
      mime_type             as MimeType,
      file_name             as Filename,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at       as LastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      local_last_changed_at as LocalLastChangedAt
}
