#include "myjsonparse.h"
#include "weatherdata.h"
#include <QVariant>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

MyJsonParse::MyJsonParse()
    : m_success(false)
{

}

MyJsonParse::MyJsonParse(const QJsonDocument &doc)
    : m_success(false),
      m_jsonDoc(doc)
{

}

MyJsonParse::~MyJsonParse()
{

}

void MyJsonParse::setJsonDocument(const QJsonDocument &doc)
{
    if (!doc.isNull())
        m_jsonDoc = doc;
    if (m_jsonDoc.isObject())
    {
        QJsonObject object = m_jsonDoc.object();
        //用于判断api返回的数据是否可用
        m_success = object.value("status").toString() == "success";
    }
}

QJsonDocument MyJsonParse::jsonDocument() const
{
    return m_jsonDoc;
}

QString MyJsonParse::getCurrentCity() const
{
    if (m_success)
    {
        QJsonObject object = m_jsonDoc.object();
        QJsonArray result = object.value("results").toArray();
        object = result[0].toObject();
        return object.value("currentCity").toString();
    }
    return "获取城市失败";
}

QString MyJsonParse::getPm25() const
{
    if (m_success)
    {
        QJsonObject object = m_jsonDoc.object();
        QJsonArray result = object.value("results").toArray();
        object = result[0].toObject();
        return object.value("pm25").toString();
    }
    return "获取PM25失败";
}

QList<IndexData *> MyJsonParse::getIndexList() const
{
    QList<IndexData *> indexs;
    if (m_success)
    {
        QJsonObject object = m_jsonDoc.object();
        QJsonArray array = object.value("results").toArray();
        object = array[0].toObject();
        array = object.value("index").toArray();
        for (auto it : array)
        {
           object = it.toObject();
           IndexData *indexData = new IndexData;
           indexData->setDescript(object.value("des").toString());
           indexData->setTipt(object.value("tipt").toString());
           indexData->setTitle(object.value("title").toString());
           indexData->setState(object.value("zs").toString());
           indexs.push_back(indexData);
        }
    }
    return indexs;
}

QList<WeatherData *> MyJsonParse::getWeatherList() const
{
    QList<WeatherData *> weathers;
    if (m_success)
    {
        QJsonObject object = m_jsonDoc.object();
        QJsonArray array = object.value("results").toArray();
        object = array[0].toObject();
        array = object.value("weather_data").toArray();
        for (auto it : array)
        {
           object = it.toObject();
           WeatherData *weatherData = new WeatherData;
           weatherData->setDate(object.value("date").toString());
           //温度的格式为 max ~ min℃;
           QString temperature = object.value("temperature").toString();
           QStringList temperatures = temperature.left(temperature.length() - 1).split(" ~ ");
           weatherData->setMaxTemperature(temperatures.at(0).toInt());
           weatherData->setMinTemperature(temperatures.at(1).toInt());
           QString weather = object.value("weather").toString();
           weatherData->setWeather(weather);
           QString imagestr;
           if (weather.left(1) == "晴")  //晴或晴转xx
               imagestr = "fine";
           else if ((weather.left(2) == "多云" ) || weather.left(1) == "阴") //多云或多云转xx  阴或阴转xx
               imagestr = "cloudy";
           else if (weather.contains("雨"))
               imagestr = "rain";
           else if (weather.contains("雪"))
               imagestr = "snow";
           else imagestr = "fine";
           weatherData->setDayPicture("qrc:/image/" + imagestr + "_sun.png");
           weatherData->setNightPicture("qrc:/image/" + imagestr + "_moon.png");
           weatherData->setWind(object.value("wind").toString());
           weathers.push_back(weatherData);
        }
    }

    return weathers;
}
