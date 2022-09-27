DELETE FROM CounterData WHERE RecordIndex NOT IN (SELECT MAX(RecordIndex) FROM CounterData)
