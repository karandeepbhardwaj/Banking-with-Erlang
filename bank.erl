-module(bank).

-export([loan_decision/2]).

loan_decision(Bank_name, Money_in_bank) ->
    receive
      {Pid, Msg} ->
	  {Customer_name, Money_required, _} = Msg,
	  if Money_required =< Money_in_bank ->
		 master !
		   {bank_accepted, Bank_name, Money_required,
		    Customer_name},
		 Pid ! {self(), accepted},
		 loan_decision(Bank_name,
			       Money_in_bank - Money_required);
	     true ->
		 Pid ! {self(), rejected},
		 master !
		   {bank_rejected, Bank_name, Customer_name,
		    Money_required, Money_in_bank},
		 master !
		   {bank_rejected, Bank_name, Customer_name,
		    Money_required, Money_in_bank},
		 loan_decision(Bank_name, Money_in_bank)
	  end
    end.
