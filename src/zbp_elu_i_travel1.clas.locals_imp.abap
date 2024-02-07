CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR travel RESULT result.
    METHODS validatedate FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatedate.
    METHODS validcustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validcustomer.
    METHODS setoverallstatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~setoverallstatus.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE travel.

ENDCLASS.

CLASS lhc_travel IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD ValidateDate.
    READ ENTITIES OF yelu_i_travel1 IN LOCAL MODE
         ENTITY travel
         FIELDS ( BeginDate EndDate TravelID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels)
         FAILED DATA(lt_failed).

    LOOP AT travels INTO DATA(travel).

      reported-travel = VALUE #( BASE reported-travel
                                 ( %tky        = travel-%tky
                                   %state_area = 'VALIDATE_DATES' ) ).

      IF travel-BeginDate IS INITIAL.
        failed-travel = VALUE #( BASE failed-travel
                                 ( %tky = travel-%tky ) ).

        reported-travel = VALUE #( BASE reported-travel
                                   ( %tky               = travel-%tky
                                     %state_area        = 'VALIDATE_DATES'
                                     %element-begindate = if_abap_behv=>mk-on
                                     %msg               = NEW /dmo/cm_flight_messages(
                                                                  textid   = /dmo/cm_flight_messages=>enter_begin_date
                                                                  severity = if_abap_behv_message=>severity-error ) ) ).
      ENDIF.

      IF travel-BeginDate < cl_abap_context_info=>get_system_date( ) AND travel-BeginDate IS NOT INITIAL.
        failed-travel = VALUE #( BASE failed-travel
                                 ( %tky = travel-%tky ) ).

        reported-travel = VALUE #( BASE reported-travel
                                   ( %tky               = travel-%tky
                                     %state_area        = 'VALIDATE_DATES'
                                     %element-begindate = if_abap_behv=>mk-on
                                     %msg               = NEW /dmo/cm_flight_messages(
                                         textid   = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                         severity = if_abap_behv_message=>severity-error ) ) ).
      ENDIF.

      IF travel-EndDate IS INITIAL.
        failed-travel = VALUE #( BASE failed-travel
                                 ( %tky = travel-%tky ) ).

        reported-travel = VALUE #( BASE reported-travel
                                   ( %tky             = travel-%tky
                                     %state_area      = 'VALIDATE_DATES'
                                     %element-enddate = if_abap_behv=>mk-on
                                     %msg             = NEW /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_end_date
                                                                severity = if_abap_behv_message=>severity-error ) ) ).
      ENDIF.

      IF     travel-EndDate  < travel-BeginDate AND travel-BeginDate IS NOT INITIAL
         AND travel-EndDate IS NOT INITIAL.

        failed-travel = VALUE #( BASE failed-travel
                                 ( %tky = travel-%tky ) ).

        reported-travel = VALUE #( BASE reported-travel
                                   ( %tky               = travel-%tky
                                     %state_area        = 'VALIDATE_DATES'
                                     %element-begindate = if_abap_behv=>mk-on
                                     %element-enddate   = if_abap_behv=>mk-on
                                     %msg               = NEW /dmo/cm_flight_messages(
                                         textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                         severity   = if_abap_behv_message=>severity-error
                                         begin_date = travel-BeginDate
                                         end_date   = travel-EndDate ) ) ).

      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD ValidCustomer.
    "Read relevant travel instance data
    READ ENTITIES OF yelu_i_travel1 IN LOCAL MODE
    ENTITY travel
     FIELDS ( CustomerID )
     WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    customers = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING
                              customer_id = CustomerID EXCEPT * ).
    DELETE customers WHERE customer_id IS INITIAL.

    "Check if customer IDs exist.
    IF customers IS NOT INITIAL.
      SELECT FROM /dmo/customer FIELDS customer_id
      FOR ALL ENTRIES IN @customers
      WHERE customer_id = @customers-customer_id
      INTO TABLE @DATA(valid_cust).
    ENDIF.

    "LOOP at Travels to fill and raise messages.
    LOOP AT travels INTO DATA(travel).

      APPEND VALUE #(  %tky                 = travel-%tky
                       %state_area          = 'VALIDATE_CUSTOMER'
                     ) TO reported-travel.

      IF travel-CustomerID IS  INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = NEW /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_customer_id
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on
                      ) TO reported-travel.

      ELSEIF travel-CustomerID IS NOT INITIAL AND NOT line_exists( valid_cust[ customer_id = travel-CustomerID ] ).
        APPEND VALUE #(  %tky = travel-%tky ) TO failed-travel.

        APPEND VALUE #(  %tky                = travel-%tky
                         %state_area         = 'VALIDATE_CUSTOMER'
                         %msg                = NEW /dmo/cm_flight_messages(
                                                                customer_id = travel-customerid
                                                                textid      = /dmo/cm_flight_messages=>customer_unkown
                                                                severity    = if_abap_behv_message=>severity-error )
                         %element-CustomerID = if_abap_behv=>mk-on
                      ) TO reported-travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD SetOverallStatus.
    CONSTANTS:
      BEGIN OF travel_status,
        open     TYPE c LENGTH 1 VALUE 'O', "Open
        accepted TYPE c LENGTH 1 VALUE 'A', "Accepted
        rejected TYPE c LENGTH 1 VALUE 'X', "Rejected
      END OF travel_status.

    READ ENTITIES OF yelu_i_travel1 IN LOCAL MODE
      ENTITY travel
      FIELDS ( OverallStatus )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels)
      FAILED DATA(read_failed).

    "If status is set, do nothing. Remove those instances.
    DELETE travels WHERE OverallStatus IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.

    MODIFY ENTITIES OF yelu_i_travel1 IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR travel IN travels
                    ( %tky = travel-%tky
                     OverallStatus = travel_status-open ) ).

  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA travel_id_max TYPE /dmo/travel_id.

    LOOP AT entities INTO DATA(entity) WHERE TravelID IS NOT INITIAL.
      APPEND CORRESPONDING #( entity ) TO mapped-travel.
    ENDLOOP.

    DATA(entities_wo_travelid) =  entities.
    DELETE entities_wo_travelid WHERE TravelID IS NOT INITIAL. "Remove entries with existing TravelID

    "Max Travel ID from active table
    SELECT SINGLE FROM yelu_i_travel1
    FIELDS MAX( TravelID ) AS travelID
    INTO @travel_id_max.

    "Max Travel ID from draft table
    SELECT SINGLE FROM yelu_d_travel1
    FIELDS MAX( TravelID )
    INTO @DATA(travel_id_draft).

    IF travel_id_draft > travel_id_max.
      travel_id_max = travel_id_draft.
    ENDIF.

    "Set Travel ID next number for instances without ID
    LOOP AT entities_wo_travelid INTO entity.
      travel_id_max += 1.
      entity-TravelID = travel_id_max.

      APPEND VALUE #( %cid      = entity-%cid
                      %key      = entity-%key
                      %is_draft = entity-%is_draft
                    ) TO mapped-travel.
    ENDLOOP.

  ENDMETHOD.





































ENDCLASS.
