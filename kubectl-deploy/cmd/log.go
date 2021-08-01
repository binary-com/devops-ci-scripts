/*
Copyright © 2021 Deriv <sysadmin@deriv.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package cmd

import (
	"fmt"

	log "github.com/sirupsen/logrus"
)

type typeOfLog int

const (
	Uncategorized typeOfLog = iota
	Info
	Warn
	Fatal
)

func logger(message string, logType typeOfLog) {
	customFormatter := new(log.TextFormatter)
	customFormatter.TimestampFormat = "2006-01-02 15:04:05"
	log.SetFormatter(customFormatter)
	customFormatter.FullTimestamp = true
	switch logType {
	case Uncategorized:
		fmt.Println(message)
	case Info:
		log.Info(message)
	case Warn:
		log.Warn(message)
	case Fatal:
		log.Fatal(message)
	default:
		fmt.Println(message)
	}
}
