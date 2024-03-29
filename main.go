package main

import (
	"flag"
	"fmt"
	"github.com/gobeam/stringy"
	"golang.org/x/text/cases"
	"golang.org/x/text/language"
	"google.golang.org/protobuf/compiler/protogen"
	"google.golang.org/protobuf/reflect/protoreflect"
	"google.golang.org/protobuf/types/pluginpb"
	"log"
	"strconv"
	"strings"
)

var (
	flags   flag.FlagSet
	version = flags.String("version", "", "version for liquibase proto")
)

var globalSource protoreflect.SourceLocations
var command string

func main() {
	protogen.Options{ParamFunc: flags.Set}.Run(func(p *protogen.Plugin) error {
		p.SupportedFeatures = uint64(pluginpb.CodeGeneratorResponse_FEATURE_PROTO3_OPTIONAL)
		for _, file := range p.Files {
			if !file.Generate {
				continue
			}
			if len(file.Messages) == 0 {
				return nil
			}
			log.Println("generating: " + file.GeneratedFilenamePrefix)

			// Load Global Options
			globalSource = file.Desc.Imports().Get(0).FileDescriptor.SourceLocations()
			var globals []protoreflect.FieldDescriptor
			g := file.Desc.Imports().Get(0).Messages().ByName("GlobalOptions")
			for i := 0; i < g.Fields().Len(); i++ {
				globals = append(globals, g.Fields().Get(i))
			}

			// Remove matching command arguments from global options
			message := getRequestMessage(file)
			fields := getFieldsFromMessage(message)
			for _, f := range fields {
				i := getIndexByName(globals, f.Desc.JSONName())
				if i != 0 {
					globals = append(globals[:i], globals[i+1:]...)
				}
			}

			// Set Command Name
			f := strings.Split(file.GeneratedFilenamePrefix, "/")
			s := stringy.New(f[len(f)-1])
			command = s.SnakeCase().ToLower()

			if err := generateActionYaml(p, file, globals); err != nil {
				return err
			}
			if err := generateBashEntry(p, file, globals); err != nil {
				return err
			}
			if err := generateDockerfile(p, file, *version); err != nil {
				return err
			}
			if err := generateReadme(p, file, *version); err != nil {
				return err
			}
		}
		return nil
	})
}

func getIndexByName(globals []protoreflect.FieldDescriptor, s string) int {
	for i, g := range globals {
		if g.JSONName() == s {
			return i
		}
	}
	return 0
}

func getRequestMessage(f *protogen.File) *protogen.Message {
	var m *protogen.Message
	for _, message := range f.Messages {
		if !strings.Contains(message.GoIdent.String(), "Response") {
			m = message
		}
	}
	return m
}
func getFieldsFromMessage(m *protogen.Message) []*protogen.Field {
	//Get Fields from nested message could be an issue if nested more than 1 level deep
	var f []*protogen.Field
	if len(m.Messages) > 0 { // build fields from nested message
		f = m.Messages[0].Fields[:len(m.Messages[0].Fields)-1] // Remove GlobalOptions from Fields
	} else {
		f = m.Fields[:len(m.Fields)-1] // Remove GlobalOptions from Fields
	}
	return f
}

func generateReadme(p *protogen.Plugin, file *protogen.File, version string) error {
	var required []*protogen.Field
	var optional []*protogen.Field
	message := getRequestMessage(file)
	fields := getFieldsFromMessage(message)
	for _, f := range fields {
		if !f.Desc.HasPresence() {
			required = append(required, f)
		} else {
			optional = append(optional, f)
		}
	}
	g := p.NewGeneratedFile("./action/"+command+"/README.md", file.GoImportPath)
	cmdReadable := strings.Replace(command, "_", " ", -1)
	c := cases.Title(language.English)
	g.P("# Liquibase " + c.String(cmdReadable) + " Action")
	g.P("Official GitHub Action to run Liquibase " + c.String(cmdReadable) + " in your GitHub Action Workflow. For more information on how " + cmdReadable + " works visit the [Official Liquibase Documentation](https://docs.liquibase.com/commands/home.html).")
	g.P("## " + c.String(cmdReadable))
	for _, l := range file.Proto.GetSourceCodeInfo().GetLocation() {
		if l.GetLeadingComments() != "" {
			g.P(strings.TrimSpace(l.GetLeadingComments()))
		}
	}
	g.P("## Usage")
	g.P("```yaml")
	g.P("steps:")
	g.P("- uses: actions/checkout@v3")
	s := stringy.New(command)
	kebab := s.KebabCase()
	g.P("- uses: liquibase-github-actions/" + kebab.ToLower() + "@v" + version)
	g.P("  with:")
	if len(required) > 0 {
		for _, f := range required {
			c := strings.TrimPrefix(f.Comments.Trailing.String(), "// *required*")
			d := strings.Replace(strings.TrimSpace(c), "'", "\"", -1)
			g.P("    # " + d)
			g.P("    # " + f.Desc.Kind().String())
			g.P("    # Required")
			g.P("    " + f.Desc.JSONName() + ": \"\"")
			g.P()
		}
	}
	if len(optional) > 0 {
		for _, f := range optional {
			c := strings.TrimPrefix(f.Comments.Trailing.String(), "// ")
			d := strings.Replace(strings.TrimSpace(c), "'", "\"", -1)
			g.P("    # " + d)
			g.P("    # " + f.Desc.Kind().String())
			g.P("    # Optional")
			g.P("    " + f.Desc.JSONName() + ": \"\"")
			g.P()
		}
	}
	g.P("```")
	g.P()
	g.P("### Secrets")
	g.P("It is a good practice to protect your database credentials with [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)")
	g.P()
	g.P("## Optional Liquibase Global Inputs")
	g.P("The liquibase " + cmdReadable + " action accepts all valid liquibase global options as optional parameters. A full list is available in the official [Liquibase Documentation](https://docs.liquibase.com/parameters/command-parameters.html).")
	g.P()
	g.P("### Example")
	g.P("```yaml")
	g.P("steps:")
	g.P("  - uses: actions/checkout@v3")
	g.P("  - uses: liquibase-github-actions/" + kebab.ToLower() + "@v" + version)
	g.P("    with:")
	if len(required) > 0 {
		for _, f := range required {
			g.P("      " + f.Desc.JSONName() + ": \"\"")
		}
	}
	g.P("      headless: true")
	g.P("      licenseKey: ${{ secrets.LIQUIBASE_LICENSE_KEY }}")
	g.P("      logLevel: INFO")
	g.P("```")
	g.P()
	g.P("## Feedback and Issues")
	g.P("This action is automatically generated. Please submit all feedback and issues with the [generator repository](https://github.com/liquibase/github-action-generator/issues).")
	return nil
}

func generateDockerfile(p *protogen.Plugin, file *protogen.File, version string) error {
	g := p.NewGeneratedFile("./action/"+command+"/Dockerfile", file.GoImportPath)
	g.P("# Code generated by protoc-gen-liquibase. DO NOT EDIT.")
	g.P("FROM liquibase/liquibase:" + version)
	g.P("COPY " + command + ".sh /entry.sh")
	g.P("ENTRYPOINT [\"/entry.sh\"]")
	return nil
}

func generateActionYaml(p *protogen.Plugin, file *protogen.File, globals []protoreflect.FieldDescriptor) error {
	g := p.NewGeneratedFile("./action/"+command+"/action.yml", file.GoImportPath)
	cmdReadable := strings.Replace(command, "_", " ", -1)
	c := cases.Title(language.English)
	g.P("# action.yml")
	g.P("# Code generated by protoc-gen-liquibase. DO NOT EDIT.")
	g.P("name: 'Liquibase " + c.String(cmdReadable) + " Action'")
	for _, l := range file.Proto.GetSourceCodeInfo().GetLocation() {
		if l.GetLeadingComments() != "" {
			g.P("description: |")
			lc := strings.TrimSpace(l.GetLeadingComments())
			if len(l.GetLeadingComments()) > 124 {
				g.P("  " + fmt.Sprintf("%.121s", lc) + "...")
			} else {
				g.P("  " + lc)
			}
		}
	}
	g.P("inputs:")
	message := getRequestMessage(file)
	fields := getFieldsFromMessage(message)
	for _, f := range fields {
		g.P("  " + string(f.Desc.JSONName()) + ": # " + f.Desc.Kind().String())
		c := strings.TrimPrefix(f.Comments.Trailing.String(), "// ")
		d := strings.Replace(strings.TrimSpace(c), "'", "\"", -1)
		g.P("    description: '" + d + "'")
		g.P("    required: " + strconv.FormatBool(!f.Desc.HasPresence()))
	}
	for _, gp := range globals {
		g.P("  " + string(gp.JSONName()) + ": # " + gp.Kind().String())
		c := strings.TrimPrefix(globalSource.ByDescriptor(gp).TrailingComments, "// ")
		d := strings.Replace(strings.TrimSpace(c), "'", "\"", -1)
		g.P("    description: '" + d + "'")
		g.P("    required: false")
	}
	g.P("runs:")
	g.P("  using: 'docker'")
	g.P("  image: 'Dockerfile'")
	g.P("  args:")
	for _, f := range fields {
		g.P("    - ${{ inputs." + string(f.Desc.JSONName()) + " }}")
	}
	for _, gp := range globals {
		g.P("    - ${{ inputs." + string(gp.JSONName()) + " }}")
	}
	g.P("branding:")
	g.P("  icon: database")
	g.P("  color: red")
	return nil
}

func generateBashEntry(p *protogen.Plugin, file *protogen.File, globals []protoreflect.FieldDescriptor) error {
	filename := file.GeneratedFilenamePrefix + ".sh"
	g := p.NewGeneratedFile(filename, file.GoImportPath)
	g.P("#!/bin/bash")
	g.P("# Code generated by protoc-gen-liquibase. DO NOT EDIT.")
	g.P()
	message := getRequestMessage(file)
	fields := getFieldsFromMessage(message)
	g.P("# Command Arguments")
	for _, f := range fields {
		g.P(strings.ToUpper(f.Desc.JSONName()) + "=${" + strconv.Itoa(int(f.Desc.Number())) + "}")
	}
	g.P("# Global Options")
	for i, gp := range globals {
		g.P(strings.ToUpper(gp.JSONName()) + "=${" + strconv.Itoa(i+len(fields)+1) + "}")
	}
	g.P()
	for _, f := range fields {
		if !f.Desc.HasPresence() {
			g.P("if [[ -z \"$" + strings.ToUpper(f.GoName) + "\" ]]; then")
			g.P("	echo \"" + f.Desc.JSONName() + " is required\"")
			g.P("	exit 1")
			g.P("fi")
		}
	}
	g.P()
	g.P("PARAMS=()")
	g.P()
	for _, f := range fields {
		s := stringy.New(string(f.Desc.Name()))
		k := s.KebabCase()
		g.P("if [[ -n \"$" + strings.ToUpper(f.GoName) + "\" ]]; then")
		g.P("	PARAMS+=(\"--" + k.ToLower() + "=$" + strings.ToUpper(f.GoName) + "\")")
		g.P("fi")
	}
	g.P()
	g.P("GLOBALS=()")
	g.P()
	for _, gp := range globals {
		s := stringy.New(gp.JSONName())
		k := s.KebabCase()
		g.P("if [[ -n \"$" + strings.ToUpper(gp.JSONName()) + "\" ]]; then")
		g.P("	GLOBALS+=(\"--" + k.ToLower() + "=$" + strings.ToUpper(gp.JSONName()) + "\")")
		g.P("fi")
	}
	g.P()
	if len(message.Messages) > 0 { // build nested command string
		var cmd string
		s := strings.TrimPrefix(string(message.Messages[0].Desc.FullName()), "liquibase.")
		for _, c := range strings.Split(s, ".") {
			d := strings.TrimSuffix(c, "Request")
			if d == "pro" {
				continue
			}
			str := stringy.New(d)
			cmd += str.KebabCase().ToLower() + " "
		}
		g.P("docker-entrypoint.sh \"${GLOBALS[@]}\" " + strings.TrimSpace(cmd) + " \"${PARAMS[@]}\"")
	} else {
		s := strings.Split(file.GeneratedFilenamePrefix, "/")
		c := stringy.New(s[len(s)-1])
		g.P("docker-entrypoint.sh \"${GLOBALS[@]}\" " + c.KebabCase().ToLower() + " \"${PARAMS[@]}\"")
	}
	return nil
}
