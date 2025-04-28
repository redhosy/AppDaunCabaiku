from fastapi import FastAPI
from pydantic import BaseModel
from enum import Enum
from typing import Optional

application = FastAPI()

class Tipe(str,Enum):
    def __str__(self):
        return str(self.value)
    INCOME = "INCOME"
    INVEST = "INVEST"
    PURCHASE = "PURCHASE"

class Method(str,Enum):  # enum untuk method pembayaran membatasi sebagai input
    def __str__(self):
        return str(self.value)
    TUNAI = "TUNAI"
    DEBIT = "DEBIT"
    KREDIT = "KREDIT"

class InputTransaksi(BaseModel):
    tipe:Tipe
    amount:int
    notes:Optional[str]
    method:Method # panggil enum Method



transaksi  = [] # simpan dalam list
# query parameter
# @application.get("/transaksi0")
# def get_transaksi(tipe:str, amount:int):
#     print(tipe, amount)
#     print(type(tipe), type(amount))
#     return f"balikan transaksi tipe {tipe} dan amount {amount}"

# Path Parameter
# @application.get("/transaksi/{tipe}")
# def get_transaksi(tipe:str):
#     print(tipe)
#     return f"balikan transaksi tipe {tipe}"


# @application.post("/transaksi1")
# def insert_transaksi(tipe:str, amount:int, notes:str, method:str):
#     data_transaksi = {
#         "tipe":tipe,
#         "amount":amount,
#         "notes":notes,
#         "method":method
#     }
#     transaksi.append(data_transaksi)
#     return transaksi


@application.post("/transaksi2")
def insert_transaksi(input_transaksi:InputTransaksi): #request body diambil dari class InputTransaksi
 
    transaksi.append(input_transaksi) # append data transaksi ke list transaksi
    return transaksi

@application.get("/transaksi")
def get_transaksi(tipe:Optional[Tipe] = None):
    if tipe is not None:
        result_filter = []
        for t in transaksi:
            t = InputTransaksi.parse_obj(t)
            if t.tipe == tipe:
                result_filter.append(t)
    else:
        result_filter = transaksi
    return result_filter
    