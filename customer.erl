-module(customer).

-export([start_customer/5]).

start_customer(Customer_name, Loan_amount, [], Original_amount, Money_until_now) ->
    master !
      {customer_not_complete, Customer_name, Loan_amount,Original_amount, Money_until_now};
start_customer(Customer_name, 0, _, Original_amount, Money_until_now) ->
    master ! {customer_complete, Customer_name, Original_amount, Money_until_now};
start_customer(Customer_name, Money_required,
	       Bank_list,Original_amount, Money_until_now) ->
    Random_wait_time = rand:uniform(90) + 10,
    timer:sleep(Random_wait_time),
    if Money_required >= 50 ->
	   Loan_amount = rand:uniform(50);
       true -> Loan_amount = rand:uniform(Money_required)
    end,
    Bank = lists:nth(rand:uniform(length(Bank_list)),
		     Bank_list),
    Bank_name = element(1, Bank),
    master !
      {customer_requested, Customer_name, Loan_amount,
       Bank_name},
    Pid_of_bank = element(3, Bank),
    Pid_of_bank !
      {self(), {Customer_name, Loan_amount, Bank}},
    receive
      {_, accepted} ->
	  start_customer(Customer_name,
			 Money_required - Loan_amount, Bank_list,Original_amount, Money_until_now+Loan_amount);
      {_, rejected} ->
	  New_list = lists:delete(Bank, Bank_list),
	  start_customer(Customer_name, Money_required, New_list,Original_amount, Money_until_now)
    end.