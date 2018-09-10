import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Window 2.3
import QtCharts 2.2
import an.weather 1.0
import an.model 1.0

ApplicationWindow
{
    id: root

    width: mobile ? Screen.desktopAvailableWidth : 400
    height: mobile ? Screen.desktopAvailableHeight : 600
    color: "#CDEDEC"
    visible: true

    property bool mobile: Qt.platform.os == "android";

    Connections
    {
        target: myModel
        onReadyChanged:
        {
            if (myModel.ready)
            {
                refreshAnimation.restart();
                maxSeries.clear();
                minSeries.clear();
                for (var i = 0; i < 4; i++)
                {
                    maxSeries.append(i + 1, myModel.weatherData[i].maxTemperature);
                    minSeries.append(i + 1, myModel.weatherData[i].minTemperature);
                }
            }
        }
    }

    NumberAnimation
    {
        id: refreshAnimation
        target: page
        property: "y"
        duration: 200
        from: page.pullHeight
        to: 0
        easing.type: Easing.Linear
    }

    Image
    {
        id: season      //季节背景
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        mipmap: true
        antialiasing: true
        opacity: 0.4
        source: getSeason()

        function getSeason()
        {
            var time = new Date();
            var season = time.getMonth() / 3;

            if (season <= 1)
                return "qrc:image/spring.png";
            else if (season > 1 && season <= 2)
                return "qrc:image/summer.png";
            else if (season > 2 && season <= 3)
                return "qrc:image/autumn.png";
            else return "qrc:image/winter.png";
        }
    }

    Component
    {
        id: delegate

        Item
        {
            width: 70
            height: 220

            Text
            {
                id: dateText
                width: 70
                height: 20
                font.family: "方正"
                font.pointSize: 10
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: index != 0 ? date : "今日"
            }

            Text
            {
                id: weatherText
                width: 70
                height: 20
                font.family: "方正"
                font.pointSize: 10
                anchors.top: dateText.bottom
                anchors.topMargin: 5
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: myModel.ready ? weather : "未知"
            }

            Image
            {
                id: day
                anchors.top: weatherText.bottom
                anchors.topMargin: 2
                width: 70
                height: 50
                mipmap: true
                fillMode: Image.PreserveAspectFit
                source: myModel.ready ? dayPicture : ""
            }

            Text
            {
                id: temperatureText
                width: 70
                height: 20
                font.family: "方正"
                font.pointSize: 10
                anchors.top: day.bottom
                anchors.topMargin: 5
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: myModel.ready ? myModel.weatherData[index].minTemperature + " ~ " +
                                      myModel.weatherData[index].maxTemperature + "℃" : "未知"
            }

            Image
            {
                id: night
                anchors.top: temperatureText.bottom
                anchors.topMargin: 5
                width: 70
                height: 50
                mipmap: true
                fillMode: Image.PreserveAspectFit
                source: myModel.ready ? nightPicture : ""
            }

            Text
            {
                id: windText
                width: 70
                height: 20
                font.family: "方正"
                font.pointSize: 10
                anchors.top: night.bottom
                anchors.topMargin: 5
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: myModel.ready ? wind : "未知"
            }
        }
    }

    Flickable
    {
        id: page
        width: parent.width
        height: parent.height
        contentWidth: content.width
        contentHeight: content.height

        property int pullHeight: 64

        states: [
            State {
                id: downRefreshState
                name: "downRefresh"
                when: page.contentY < -page.pullHeight
                StateChangeScript
                {
                    script:
                    {
                        print("下拉刷新")
                        page.y = page.pullHeight
                        myModel.downRefresh();
                    }
                }
            }
        ]

        Item
        {
            id: content
            width: root.width
            height: tipsRect.y + tipsRect.height + 50

            Text
            {
                id: city
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 5
                font.pointSize: 18
                font.family: "方正"
                text: "城市：" + (myModel.ready ? myModel.city : "载入中...")
            }

            Text
            {
                id: updateMsg
                anchors.horizontalCenter: city.horizontalCenter
                anchors.top: city.bottom
                anchors.topMargin: 5
                font.pointSize: 8
                font.family: "方正"
                color: "gray"
                text: myModel.ready ? "天气数据已经更新" : "天气数据更新中...."
            }

            Text
            {
                id: temperature
                anchors.horizontalCenter: updateMsg.horizontalCenter
                anchors.top: updateMsg.bottom
                anchors.topMargin: 70
                font.pointSize: 14
                font.family: "方正"
                text: "今日温度：" + (myModel.ready ? myModel.weatherData[0].minTemperature
                                   + " ~ " + myModel.weatherData[0].maxTemperature + "℃": "载入中...")
            }

            Text
            {
                id: pm25
                anchors.horizontalCenter: temperature.horizontalCenter
                anchors.top: temperature.bottom
                anchors.topMargin: 10
                font.pointSize: 14
                font.family: "方正"
                text: "空气污染(PM2.5)：" + (myModel.ready ? myModel.pm25 + calcPollutionLevel(myModel.pm25) : "载入中...")
                function calcPollutionLevel(arg)
                {
                    var intArg = parseInt(arg);
                    if (intArg >= 0 && intArg < 35)
                        return "(优秀)";
                    else if (intArg >= 35 && intArg < 75)
                        return "(良好)";
                    else if (intArg >= 75 && intArg < 115)
                        return "(轻度污染)";
                    else if (intArg >= 115 && intArg < 150)
                        return "(中度污染)";
                    else if (intArg >= 150 && intArg < 250)
                        return "(重度污染)";
                    else return "(严重污染)";
                }
            }

            Text
            {
                id: time
                anchors.horizontalCenter: pm25.horizontalCenter
                anchors.top: pm25.bottom
                anchors.topMargin: 10
                font.pointSize: 14
                font.family: "方正"
                color: "red"
                text: myModel.ready ? myModel.weatherData[0].date : "载入中..."
            }

            Row
            {
                id: day_night
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: time.bottom
                anchors.topMargin: 10
                spacing: 15

                Image
                {
                    width: 100
                    height: 50
                    mipmap: true
                    fillMode: Image.PreserveAspectFit
                    source: myModel.ready ? myModel.weatherData[0].dayPicture : ""
                }

                Image
                {
                    width: 100
                    height: 50
                    mipmap: true
                    fillMode: Image.PreserveAspectFit
                    source: myModel.ready ? myModel.weatherData[0].nightPicture : ""
                }
            }

            Row
            {
                id: day_night_text
                anchors.top: day_night.bottom
                anchors.topMargin: 2
                anchors.horizontalCenter: day_night.horizontalCenter

                Text
                {
                    width: 120
                    height: 20
                    font.pointSize: 11
                    font.family: "方正"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: qsTr("白天")
                }

                Text
                {
                    width: 120
                    height: 20
                    font.pointSize: 11
                    font.family: "方正"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: qsTr("夜晚")
                }
            }

            ListView
            {
                id: futureWeather
                width: contentWidth
                orientation: ListView.Horizontal
                anchors.top: day_night_text.bottom
                anchors.topMargin: 50
                anchors.horizontalCenter: day_night_text.horizontalCenter
                spacing: 20
                model: myModel.weatherData
                delegate: delegate
            }

            ChartView
            {
                id: futureChart
                width: parent.width
                height: 200
                legend.font.family: "方正"
                legend.font.pointSize: 10
                y: futureWeather.y + 190
                anchors.horizontalCenter: futureWeather.horizontalCenter
                antialiasing: true
                backgroundColor: "transparent"
                plotAreaColor: "transparent"
                Component.onCompleted:
                {
                    futureChart.axisX().visible = false;
                    futureChart.axisY().visible = false;
                }

                ValueAxis
                {
                    id: axisX
                    min: 0.5
                    max: 4.5
                }

                ValueAxis
                {
                    id: axisY
                    min: -5
                    max: 40
                }

                LineSeries
                {
                    id: maxSeries
                    name: "最高温"
                    pointLabelsFont.family: "方正"
                    pointLabelsFont.pointSize: 10
                    pointLabelsVisible: true
                    pointLabelsFormat: "@yPoint °"  //更改label的格式
                    color: "red"
                    width: 2
                    axisX: axisX
                    axisY: axisY
                }

                LineSeries
                {
                    id: minSeries
                    name: "最低温"
                    pointLabelsFont.family: "方正"
                    pointLabelsFont.pointSize: 10
                    pointLabelsVisible: true
                    pointLabelsFormat: "@yPoint °"
                    color: "#8080FF"
                    width: 2
                    axisX: axisX
                    axisY: axisY
                }
            }

            Rectangle
            {
                id: tipsRect
                width: parent.width - 40
                height: 280
                radius: 5
                clip: true
                anchors.top: futureChart.bottom
                anchors.topMargin: 10
                anchors.horizontalCenter: futureWeather.horizontalCenter
                color: "#335C8D89"

                Text
                {
                    id: tipsText
                    text: "小提示:"
                    anchors.left: tipsRect.left
                    anchors.leftMargin: 15
                    anchors.top: tipsRect.top
                    anchors.topMargin: 15
                    font.pointSize: 13
                    font.bold: true
                    font.family: "方正"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: "#FC993C"
                }

                Flickable   //之所以使用一个Flickable，是因为下面的ListView的滑动失效了，具体原因不明
                {
                    anchors.left: tipsRect.left
                    anchors.leftMargin: 10
                    anchors.right: tipsRect.right
                    anchors.rightMargin: 10
                    anchors.top: tipsText.bottom
                    anchors.topMargin: 10
                    width: parent.width
                    height: parent.height
                    contentWidth: tipsView.contentWidth
                    contentHeight: tipsView.contentHeight

                    ListView
                    {
                        id: tipsView
                        height: parent.width
                        width: parent.width
                        orientation: ListView.Horizontal
                        model: myModel.indexData
                        spacing: 20
                        delegate: Component
                        {
                            Column
                            {
                                spacing: 20

                                Text
                                {
                                    id: title
                                    width: 80
                                    text: modelData.title
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pointSize: 11
                                    font.family: "方正"
                                }

                                Text
                                {
                                    id: tipt
                                    width: 80
                                    text: modelData.tipt
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pointSize: 11
                                    font.family: "方正"
                                }

                                Text
                                {
                                    id: state
                                    width: 80
                                    text: modelData.state
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pointSize: 11
                                    font.family: "方正"
                                }

                                Text
                                {
                                    id: descript
                                    width: 80
                                    text: modelData.descript
                                    wrapMode: Text.Wrap
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pointSize: 11
                                    font.family: "方正"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
