/* Retired native objects and omitted queue work return capacity locally; the
   budget callback batches cumulative totals rather than one RPC per particle. */
if (isRemoteExecuted) exitWith {};
params ["_serial", "_count"];
private _receipts = localNamespace getVariable "KPLIB_munitionsBudgetReceipts";
if (isNil "_receipts") exitWith {};
private _receipt = _receipts getOrDefault [_serial, []];
if (_receipt isEqualTo []) exitWith {};
_receipt set [1, ((_receipt select 1) + _count) min (_receipt select 0)];
