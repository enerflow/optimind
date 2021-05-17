
function toDataFramesDf(df::PyObject)

    # Convert PyObject(Pandas)/DataFrame -> DataFrames/DataFrame

    colnames = map(Symbol, df.columns)
    indexnames = map(Symbol, df.index.names)

    df_index = DataFrames.DataFrame()
    [df_index[!,indexnames[indx]] = DateTime.(df.index.get_level_values(indexnames[indx])) for indx in 1:length(indexnames)]

    df = Pandas.DataFrame(df)
    df_values = DataFrame(df)

    df_new = hcat(df_index,df_values)

    return df_new
end

function toPandasDf(df::DataFrame)

    # Convert DataFrames/DataFrame -> PyObject(Pandas)/DataFrame

    colnames = names(df)
    df_new = Pandas.DataFrame(df)
    df_new = df_new[colnames]

    return df_new
end


function toDataFramesDf_(df::PyObject)

    # Convert PyObject(Pandas)/DataFrame -> DataFrames/DataFrame

    colnames = map(Symbol, df.columns)
    indexnames = map(Symbol, df.index.names)

    df_new = DataFrames.DataFrame()
    [df_new[!,indexnames[indx]] = DateTime.(df.index.get_level_values(indexnames[indx])) for indx in 1:length(indexnames)]

    for c in colnames
        df_new[!,c] = convert.(Float64, collect(get(df, c)))
    end

    return df_new
end
