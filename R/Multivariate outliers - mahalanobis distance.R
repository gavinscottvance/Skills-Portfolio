data  <- read_csv("Cues to Infidelity - MEN ONLY 7.12.23.csv")

df <- data.frame(data$REACT, data$SUS, data$SOI, data$SMIRB) 

df

df$mah <- mahalanobis(df, colMeans(df), cov(df))

df

df$pvalue <- pchisq(df$mah, df=3, lower.tail = FALSE)

df

df[order(df$pvalue),]

df_no_multi_outliers <- df[-(which(df$pvalue < .001)),]

df_no_multi_outliers
