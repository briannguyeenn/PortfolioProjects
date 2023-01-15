# Load packages
library(tidyr)
library(tidyverse)
library(janitor)
library(lubridate)
library(scales)
library(viridis)
library(RColorBrewer)

# Load in csv files
daily_activity <- read_csv("~/case_study_2/Fitabase Data 4.12.16-5.12.16/dailyActivity_merged.csv")
hourly_calories <- read_csv("~/case_study_2/Fitabase Data 4.12.16-5.12.16/hourlyCalories_merged.csv")
sleep_day <- read_csv("~/case_study_2/Fitabase Data 4.12.16-5.12.16/sleepDay_merged.csv")
hourly_steps <- read_csv("~/case_study_2/Fitabase Data 4.12.16-5.12.16/hourlySteps_merged.csv")
hourly_intensities <- read_csv("~/case_study_2/Fitabase Data 4.12.16-5.12.16/hourlyIntensities_merged.csv")

# Preview datasets
head(daily_activity)
head(hourly_calories)
head(sleep_day)
head(hourly_steps)
head(hourly_intensities)

# Verifying the number of users
n_distinct(daily_activity$Id)
n_distinct(hourly_steps$Id)
n_distinct(hourly_intensities$Id)
n_distinct(hourly_calories$Id)
n_distinct(sleep_day$Id)
n_distinct(daily_activity$Date)

# Formatting data and time columns
daily_activity$ActivityDate = as.Date(daily_activity$ActivityDate, format = "%m/%d/%Y")
hourly_intensities$ActivityHour = as_datetime(hourly_intensities$ActivityHour, format = "%m/%d/%Y %I:%M:%S %p", tz = Sys.timezone())
hourly_calories$ActivityHour = as_datetime(hourly_calories$ActivityHour, format = "%m/%d/%Y %I:%M:%S %p", tz = Sys.timezone())
hourly_steps$ActivityHour = as_datetime(hourly_steps$ActivityHour, format = "%m/%d/%Y %I:%M:%S %p", tz = Sys.timezone())
sleep_day$SleepDay = as_datetime(sleep_day$SleepDay, format = "%m/%d/%Y %I:%M:%S %p", tz = Sys.timezone())

# Summary Statistics
daily_activity %>% 
  select(TotalSteps,
         TotalDistance,
         SedentaryMinutes,
         Calories) %>% 
  summary()

hourly_intensities %>% 
  select(TotalIntensity,
         AverageIntensity) %>% 
  summary()

hourly_steps %>% 
  select(StepTotal) %>% 
  summary()

hourly_calories %>% 
  select(Calories) %>% 
  summary()

sleep_day %>% 
  select(TotalSleepRecords,
         TotalMinutesAsleep,
         TotalTimeInBed) %>% 
  summary()

# Checked for duplication and only "sleep_day" had 3 dupes which I removed
sum(duplicated(daily_activity))
sum(duplicated(hourly_steps))
sum(duplicated(hourly_calories))
sum(duplicated(total_intensity))
sum(duplicated(sleep_day))
sleep_day <- sleep_day %>% 
  distinct() %>% 
  drop_na()

# Checked for null values
sum(is.na(daily_activity))
sum(is.na(hourly_steps))
sum(is.na(hourly_calories))
sum(is.na(total_intensity))
sum(is.na(sleep_day))

# Renamed for consistency
daily_activity <- rename(daily_activity, Date = ActivityDate)
hourly_intensities <- rename(hourly_intensities, DateTime = ActivityHour)
hourly_calories <- rename(hourly_calories, DateTime = ActivityHour)
hourly_steps <- hourly_steps %>% 
  rename("DateTime" = "ActivityHour",
         "TotalSteps" = "StepTotal")
sleep_day <- rename(sleep_day, Date = SleepDay)

# Merged 'daily_activity' and 'sleep_day' data frames
daily_activity_sleep <- merge(daily_activity, sleep_day, by = c("Id","Date"))

# Merged hourlies
hourlies_merged <- merge(hourly_intensities, hourly_steps, by = c("Id", "DateTime"))
hourlies_merged <- merge(hourly_calories, hourlies_merged, by = c("Id", "DateTime"))

# Grouping how often people tracked their health
daily_use <- daily_activity %>% 
  filter(TotalSteps > 250) %>% 
  group_by(Id) %>% 
  summarize(Date = sum(n())) %>% 
  mutate(Frequency = case_when(
    Date >= 1 & Date <= 10 ~ "Low Usage",
    Date >= 11 & Date <=20 ~ "Normal Usage",
    Date >=21 & Date <=31 ~ "High Usage")) %>% 
  mutate(Frequency = factor(Frequency, level = c("Low Usage", "Normal Usage", "High Usage"))) %>% 
  rename(DaysUsed = Date) %>% 
  group_by(Frequency)

# Transforming daily_use df to create a pie chart
daily_use_percentage <- daily_use %>% 
  group_by(Frequency) %>% 
  summarize(Users = n_distinct(Id)) %>%
  mutate(Percent = Users/sum(Users)) %>% 
  arrange(Users) %>%
  mutate(Percent = scales::percent(Percent)) 

# Visualization pie chart for users analysis
ggplot(data = daily_use_percentage, aes(fill = Frequency, y = Users, x = ""))+
  geom_bar(stat = "identity", width = 1, color = "white")+
  coord_polar("y", start = 0)+
  scale_fill_brewer(palette = 'Blues')+
  theme_void()+
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        panel.border = element_blank(),
        panel.grid = element_blank(),
        axis.ticks = element_blank(),
        axis.text.x = element_blank(),
        plot.title = element_text(hjust = 0.5, vjust = -4, size = 16, face = "bold"))+
  geom_text(aes(label = Percent, x = 1.2), position = position_stack(vjust = 0.6))+
  labs(title = "Users Analysis")+
  guides(fill = guide_legend(title = "Usage Type"))
ggsave("Users Analysis.png")

# Visualization finding the correlation b/w Total Steps &. Calories
ggplot(data=daily_activity, aes(x=TotalSteps, y=Calories))+
  geom_point() + geom_smooth()+ 
  labs(title="Total Steps vs. Calories")
ggsave("Total Steps vs Calories.png")

# Visualization finding the relationship b/w Total Minutes Asleep & Total Sedentary Minutes
ggplot(data=daily_activity_sleep, aes(x=TotalMinutesAsleep, y=SedentaryMinutes))+
  geom_point() + geom_smooth()+
  labs(title="Minutes Asleep vs. Sedentary Minutes", x="Total Minutes Slept", y="Sedentary Minutes")
ggsave("Minutes Asleep vs Sedentary Minutes.png")

# Made new df to clean and organize only Time and the Mean Total Intensity
total_intensity <- hourlies_merged %>% 
  group_by(Time) %>% 
  summarise(AvgTotalIntensity = mean(TotalIntensity))

#Separating DateTime
hourlies_merged <- hourlies_merged %>% 
  separate(DateTime, into=c('Date', 'Time'), sep=' ')

# Visualization finding if there is a correlation between the Time of Day & Total Intensity
ggplot(data=total_intensity, aes(x=Time, y=AvgTotalIntensity))+
  geom_histogram(stat = "identity", fill = "blue")+
  theme(axis.text.x = element_text(angle = 90))+
  labs(title="Average of Total Intensity vs. Time", y="Average Total Intensity")
ggsave("Average of Total Intensity vs Time.png")

# Finding the average of Total Steps Hourly
hourlies_merged <- hourlies_merged %>%
  separate(DateTime, into=c('Date', 'Time'), sep=' ') %>% 
  group_by(Time) %>% 
  mutate(AvgStepsHourly = mean(TotalSteps)) 
view(hourlies_merged)

# Visualization for Average Steps Per Hour
ggplot(data=hourlies_merged, aes(x=Time, y=AvgStepsHourly, group=1)) +
  geom_line(color = 'purple', linewidth=1) + 
  theme(axis.text.x = element_text(angle = 90))+
  labs(title="Average Steps Per Hour")+
  xlab("The Hour of Day") + ylab("Average Steps") +
  annotate("rect", xmin = "11:00:00", xmax = "15:00:00",
           ymin = 0, ymax = 700, alpha = .2) +
  annotate("rect", xmin = "16:00:00", xmax = "20:00:00",
           ymin = 0, ymax = 700, alpha = .2)+ 
  annotate("text", x = "13:00:00", y = 650,
           label = "Afternoon", hjust = 'center', size = 4)+
  annotate("text", x = "18:00:00", y = 650,
           label = "Evening", hjust = 'center', size = 4)
ggsave("Average Steps Per Hour.png")
  
# Visualization Sedentary Minutes vs Calories for "daily_activity" ?!?!?!?!??!?!!?
avg_sedentary_minutes_calories <- daily_activity %>% 
  group_by(Id) %>%
  summarize(AvgSedentaryMin = mean(SedentaryMinutes),
            AvgCalories = mean(Calories))

avg_sedentary_minutes_calories <- daily_activity %>%
  select(Id, Date, TotalSteps, SedentaryMinutes, Calories)

ggplot(data=avg_sedentary_minutes_calories, aes(x=SedentaryMinutes, y=TotalSteps))+
  geom_point() + geom_smooth()

# Visualization b/w Total Minutes Asleep & Total Time In Bed
ggplot(data=sleep_day, aes(x = TotalTimeInBed, y = TotalMinutesAsleep))+
  geom_point() + geom_smooth()+
  labs(title="Total Minutes Asleep vs. Total Time In Bed",
       x= "Total Minutes Asleep", y= "Total Time In Bed")
ggsave("Total Minutes Asleep vs Total Time In Bed.png")
