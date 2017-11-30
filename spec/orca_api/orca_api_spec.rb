require "spec_helper"

RSpec.describe OrcaApi::OrcaApi do
  let(:uri) { "http://ormaster:ormaster_password@example.com:18000" }
  let(:options) { {} }
  let(:orca_api) { OrcaApi::OrcaApi.new(uri, options) }

  describe ".new" do
    subject { orca_api }

    context "uriで認証情報を指定する" do
      let(:uri) { "http://ormaster:ormaster_password@example.com:18000" }
      let(:options) { {} }

      shared_examples "認証情報が正しいこと" do
        %i(user password).each do |sym|
          its(sym) { is_expected.to eq(URI.parse(uri).send(sym)) }
        end
      end

      include_examples "認証情報が正しいこと"

      describe "optionsよりもuriのほうが優先順位が高い" do
        let(:options) {
          {
            user: "options_ormaster",
            password: "options_ormaster_password",
          }
        }

        include_examples "認証情報が正しいこと"
      end
    end

    context "optionsで認証情報を指定する" do
      let(:uri) { "http://example.com" }
      let(:options) {
        {
          user: "ormaster",
          password: "ormaster_password",
        }
      }

      %i(user password).each do |sym|
        its(sym) { is_expected.to eq(options[sym]) }
      end
    end

    context "HTTPS + クライアント証明書を指定する" do
      let(:uri) { "https://ormaster:ormaster_password@example.com:18000" }
      let(:options) {
        {
          ssl: {
            ca_file: "path/to/ca_file",
            ca_path: "path/to/ca_path",
            p12: double("OpenSSL::PKCS12", certificate: "CERTIFICATE", key: "KEY"),
          }
        }
      }

      its(:use_ssl) { is_expected.to be(true) }
      its(:ca_file) { is_expected.to eq(options[:ssl][:ca_file]) }
      its(:ca_path) { is_expected.to eq(options[:ssl][:ca_path]) }
      its(:verify_mode) { is_expected.to eq(OpenSSL::SSL::VERIFY_PEER) }
      its(:cert) { is_expected.to eq(options[:ssl][:p12].certificate) }
      its(:key) { is_expected.to eq(options[:ssl][:p12].key) }

      describe "use_sslよりもuriにhttpsを指定することが優先される" do
        let(:options) { super().merge(use_ssl: false) }

        its(:use_ssl) { is_expected.to be(true) }
      end

      describe "verify_mode" do
        subject { super().verify_mode }

        let(:options) {
          opts = super()
          if !verify_mode.nil?
            opts[:ssl][:verify_mode] = verify_mode
          end
          if !verify.nil?
            opts[:ssl][:verify] = verify
          end
          opts
        }

        context "verify_modeを指定する" do
          let(:verify_mode) { OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT }
          let(:verify) { nil }

          it { is_expected.to eq(verify_mode) }
        end

        context "verify_modeを指定しない" do
          let(:verify_mode) { nil }

          context "verifyにtrueを指定する" do
            let(:verify) { true }

            it { is_expected.to eq(OpenSSL::SSL::VERIFY_PEER) }
          end

          context "verifyにfalseを指定する" do
            let(:verify) { false }

            it { is_expected.to eq(OpenSSL::SSL::VERIFY_NONE) }
          end

          context "verifyにtrueを指定しない" do
            let(:verify) { nil }

            it { is_expected.to eq(OpenSSL::SSL::VERIFY_PEER) }
          end
        end
      end

      describe "クライアント証明書と鍵" do
        context "p12を指定する" do
          let(:options) {
            {
              ssl: {
                p12: double("OpenSSL::PKCS12", certificate: "CERTIFICATE", key: "KEY"),
              }
            }
          }

          its(:cert) { is_expected.to eq(options[:ssl][:p12].certificate) }
          its(:key) { is_expected.to eq(options[:ssl][:p12].key) }
        end

        context "p12を指定しない" do
          context "certとkeyを指定する" do
            let(:options) {
              {
                ssl: {
                  cert: "CERTIFICATE",
                  key: "KEY",
                }
              }
            }

            its(:cert) { is_expected.to eq(options[:ssl][:cert]) }
            its(:key) { is_expected.to eq(options[:ssl][:key]) }
          end

          context "certとkeyを指定しない" do
            let(:options) {
              {
                ssl: {}
              }
            }

            its(:cert) { is_expected.to be_nil }
            its(:key) { is_expected.to be_nil }
          end
        end
      end
    end
  end

  describe "#karte_uid" do
    subject { orca_api.karte_uid }

    context "karte_uidを設定済み" do
      before do
        orca_api.karte_uid = "user_specified_karte_uid"
      end

      it { is_expected.to eq("user_specified_karte_uid") }
    end

    context "karte_uidを未設定" do
      it "SecureRandom.uuidを使ってkarte_uidを自動生成すること" do
        expect(SecureRandom).to receive(:uuid).and_return("generated uuid").once
        is_expected.to eq("generated uuid")
      end
    end
  end

  describe "#debug_ouput=" do
    let(:http) { spy("Net::HTTP") }

    before do
      allow(Net::HTTP).to receive(:new).and_return(http)
      orca_api.debug_output = $stdout
      orca_api.call("/path/to/api")
    end

    it { expect(http).to have_received(:set_debug_output).with($stdout) }
  end

  describe "#call" do
    shared_examples "日レセAPIを呼び出せること" do
      let(:request_url) {
        u = URI.parse(uri)
        "#{u.scheme}://#{u.host}:#{u.port}"
      }
      let(:result) {
        load_orca_api_response(path[1..-1].gsub("/", "_") + ".json")
      }

      subject {
        orca_api.call(path, params: params, body: body, http_method: http_method)
      }

      before do
        query = URI.encode_www_form(params.merge(format: "json"))
        stub_request(http_method, URI.join(request_url, path, "?#{query}")).
          with(body: body ? body.to_json : nil).
          to_return(body: result)
      end

      describe "/api01rv2/patientgetv2" do
        let(:path) { "/api01rv2/patientgetv2" }
        let(:params) {
          { id: "1" }
        }
        let(:body) { nil }
        let(:http_method) { :get }

        it { is_expected.to eq(result) }
      end

      describe "/api01rv2/patientlst1v2" do
        let(:path) { "/api01rv2/patientlst1v2" }
        let(:params) {
          { "class" => "01" }
        }
        let(:body) {
          {
            "patientlst1req" => {
              "Base_StartDate" => "2012-06-01",
              "Base_EndDate" => "2012-06-30",
              "Contain_TestPatient_Flag" => 1,
            }
          }
        }
        let(:http_method) { :post }

        it { is_expected.to eq(result) }
      end
    end

    context "HTTP + BASIC認証" do
      let(:uri) { "http://ormaster:ormaster_password@example.com:18000" }
      let(:options) { {} }

      include_examples "日レセAPIを呼び出せること"
    end

    context "HTTPS + クライアント証明書 + BASIC認証" do
      let(:uri) { "https://ormaster:ormaster_password@example.com:18000" }
      let(:options) {
        {
          ssl: {
            ca_file: "path/to/ca_file",
            ca_path: "path/to/ca_path",
            p12: double("OpenSSL::PKCS12", certificate: "CERTIFICATE", key: "KEY"),
          }
        }
      }

      include_examples "日レセAPIを呼び出せること"
    end

    context "bodyにハッシュ以外のオブジェクトを指定する" do
      let(:uri) { "http://ormaster:ormaster_password@example.com:18000" }
      let(:options) { {} }

      # HACK: spyにはもともとto_jsonというメソッドが定義されているため、明示的に指定する必要がある
      let(:body) { spy("body", to_json: "json") }

      before do
        allow(Net::HTTP).to receive(:new).and_return(spy("Net::HTTP"))
        orca_api.call("/path/to/api", body: body)
      end

      it { expect(body).to have_received(:to_json) }
    end

    context "異常系" do
      let(:request_url) {
        u = URI.parse(uri)
        "#{u.scheme}://#{u.host}:#{u.port}"
      }
      let(:query) { URI.encode_www_form({ format: "json" }) }

      context "HTTPのレスポンスが200以外" do
        it do
          path = "/api01rv2/imagegetv2"
          stub_request(:post, URI.join(request_url, path, "?#{query}")).to_return(body: "", status: 404)

          expect { orca_api.call(path) }.to raise_error(OrcaApi::HttpError)
        end
      end

      context "リクエストのヘッダとボディが1MiB以上であるため、Net::HTTP#requestでErrno::EPIPEの例外が発生する" do
        it do
          path = "/api01rv2/patientlst1v2"
          stub_request(:post, URI.join(request_url, path, "?#{query}")).to_raise(Errno::EPIPE)

          expect { orca_api.call(path) }.to raise_error(Errno::EPIPE)
        end
      end
    end
  end

  [
    ["new_patient_service", OrcaApi::PatientService],
    ["new_insurance_service", OrcaApi::InsuranceService],
    ["new_department_service", OrcaApi::DepartmentService],
    ["new_physician_service", OrcaApi::PhysicianService],
    ["new_medical_practice_service", OrcaApi::MedicalPracticeService],
    ["new_acceptance_service", OrcaApi::AcceptanceService],
    ["new_disease_service", OrcaApi::DiseaseService],
    ["new_form_data_service", OrcaApi::FormDataService],
    ["new_income_service", OrcaApi::IncomeService],
    ["new_print_service", OrcaApi::PrintService],
    ["new_image_service", OrcaApi::ImageService],
    ["new_receipt_service", OrcaApi::ReceiptService],
  ].each do |method_name, service_class|
    describe "##{method_name}" do
      subject { orca_api.send(method_name) }

      it { is_expected.to be_instance_of(service_class) }
      its(:orca_api) { is_expected.to eq(orca_api) }
    end
  end
end
