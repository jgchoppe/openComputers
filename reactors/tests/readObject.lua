local data = {
    reactor1 = {
        msg = "test"
    },
    reactor2 = {
        msg = "test"
    },
    reactor3 = {
        msg = "test"
    },
}

for k, x in pairs(data) do
	print('Key: '..k..', Value: ')
    print(x.msg)
end