-module(money).

-export([start/0]).

read_Customers_File() ->
    {ok, Data_From_Customers} =
	file:consult("customers.txt"),
    Data_From_Customers.

read_Banks_File() ->
    {ok, Data_From_Banks} = file:consult("banks.txt"),
    Data_From_Banks.

print_lists_from_files(Data) ->
    lists:foreach(fun (Temp) ->
			  {Name, Money} = Temp,
			  {io:fwrite("~p - ~p~n", [Name, Money])}
		  end,
		  Data).

get_bank_pid([N | T]) -> get_bank_pid([N | T], []).

get_bank_pid([], Acc) -> Acc;
get_bank_pid([N | T], Acc) ->
    {Bank_name, Money_for_loan} = N,
    Pid_For_Bank = spawn(bank, loan_decision,
			 [Bank_name, Money_for_loan]),
    get_bank_pid(T, [Pid_For_Bank | Acc]).

get_customer_pid([N | T], Bank_list) ->
    get_customer_pid([N | T], [], Bank_list).

get_customer_pid([], Acc, _) -> Acc;
get_customer_pid([N | T], Acc, Bank_list) ->
    {Customer_name, Money_required} = N,
    Money_until_now =0,
    Pid_For_Customer = spawn(customer, start_customer,
			     [Customer_name, Money_required, Bank_list, Money_required,Money_until_now]),
    get_customer_pid(T, [Pid_For_Customer | Acc],
		     Bank_list).

zip_bank_with_ids(Banks, BankIds) ->
    zip_bank_with_ids(Banks, BankIds, []).

zip_bank_with_ids([], _, Acm) -> Acm;
zip_bank_with_ids([{Name, Amount} | Rest],
		  [BankId | RestIds], Acm) ->
    zip_bank_with_ids(Rest, RestIds,
		      [{Name, Amount, BankId} | Acm]).

start() ->
    io:format("*************************************~n"),
    io:format("*   Customers and Loan objectives   "
	      "*~n"),
    io:format("*************************************~n"),
    print_lists_from_files(read_Customers_File()),
    io:format("*************************************~n"),
    io:format("*   Banks and Financial resources   "
	      "*~n"),
    io:format("*************************************~n"),
    print_lists_from_files(read_Banks_File()),
    Banks = read_Banks_File(),
    BankIds = get_bank_pid(Banks),
    BankWithIds = zip_bank_with_ids(Banks, BankIds),
    get_customer_pid(read_Customers_File(), BankWithIds),
    register(master, self()),
    master().

master() ->
    receive
      {customer_requested, CustomerName, Amount, Bank_name} ->
	  io:format("~p requests a loan of ~p dollar(s) from "
		    "~p~n",
            [CustomerName, Amount, Bank_name]),
            master();
      {bank_accepted, Bank_name, Money_required,
       Customer_name} ->
	  io:format("~p approves a loan of ~p dollars from "
		    "~p~n",
		    [Bank_name, Money_required, Customer_name]),
            master();
      {bank_rejected, Bank_name, Customer_name,
       Money_required, Money_in_bank} ->
	  io:format("~p denies a loan of ~p dollars from "
		    "~p~n",
		    [Bank_name, Money_required, Customer_name]),
	  io:format("~p has ~p dollar(s) remaining.~n",
		    [Bank_name, Money_in_bank]),
            master();
      {customer_complete, CustomerName, Original_amount,_} ->
	  io:format("~p has reached the objective of ~p "
		    "dollar(s). Woo Hoo!~n",
		    [CustomerName, Original_amount]),
            master();
      {customer_not_complete, Customer_name, _,_, Money_until_now} ->
	  io:format("~p was only able to borrow ~p dollar(s). "
		    "Boo Hoo!~n",
		    [Customer_name, Money_until_now]),
	  master()
    
      after 500 -> ok
    end.
